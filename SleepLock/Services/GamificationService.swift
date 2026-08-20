import Foundation
import SwiftData

@Observable
@MainActor
final class GamificationService {
    private let modelContext: ModelContext

    private(set) var gamificationProfile: GamificationProfile?
    private(set) var dailyQuests: [Quest] = []
    private(set) var weeklyQuests: [Quest] = []
    private(set) var badges: [Badge] = []
    private(set) var unlockedBadges: [Badge] = []

    private(set) var lastLevelUpLevel: SleepLevel?
    private(set) var showLevelUpAnimation = false
    private(set) var completedQuestThisSession: Quest?
    private(set) var unlockedBadgeThisSession: Badge?

    /// Most recent streak reported by a caller — lets badge checks triggered by
    /// XP/level changes still evaluate streak conditions.
    private var lastKnownStreak = 0

    /// Re-entrancy guard for the badge fixpoint loop: unlocking a badge awards
    /// XP, which can level the user up, which can unlock further badges.
    private var badgeCheckInProgress = false
    private var needsBadgeRecheck = false

    /// Total completed quests across daily + weekly. Computed once per access
    /// instead of filtering twice inside a view body on every re-render.
    var completedQuestCount: Int {
        dailyQuests.reduce(0) { $0 + ($1.isCompleted ? 1 : 0) }
            + weeklyQuests.reduce(0) { $0 + ($1.isCompleted ? 1 : 0) }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadGamificationData()
    }

    // MARK: - Initialization & Loading

    private func loadGamificationData() {
        do {
            let descriptor = FetchDescriptor<GamificationProfile>()
            let profiles = try modelContext.fetch(descriptor)

            if let profile = profiles.first {
                self.gamificationProfile = profile
                // Repair profiles written by the old leveling math, which
                // treated cumulative thresholds as per-level costs.
                let before = (profile.currentLevel, profile.xpInCurrentLevel)
                profile.reconcileLevelFromTotalXP()
                if before != (profile.currentLevel, profile.xpInCurrentLevel) {
                    try modelContext.save()
                }
            } else {
                let newProfile = GamificationProfile(userId: UUID())
                modelContext.insert(newProfile)
                self.gamificationProfile = newProfile
                try modelContext.save()
            }

            loadQuests()
            loadBadges()
        } catch {
            print("[GamificationService] Error loading gamification data: \(error)")
        }
    }

    /// Re-syncs quests and badges from the store — call on view appearance so a
    /// day rollover (expired dailies) is reflected without relaunching.
    func refresh() {
        loadQuests()
        loadBadges()
    }

    private func loadQuests() {
        guard let profile = gamificationProfile else { return }

        do {
            let uid = profile.userId
            var descriptor = FetchDescriptor<Quest>(
                predicate: #Predicate { $0.userId == uid },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            descriptor.fetchLimit = 50
            let userQuests = try modelContext.fetch(descriptor)

            dailyQuests = userQuests.filter { $0.type == .daily && !isQuestExpired($0) }
            weeklyQuests = userQuests.filter { $0.type == .weekly && !isQuestExpired($0) }

            regenerateExpiredQuests()
        } catch {
            print("[GamificationService] Error loading quests: \(error)")
        }
    }

    private func loadBadges() {
        guard let profile = gamificationProfile else { return }

        do {
            let uid = profile.userId
            let descriptor = FetchDescriptor<Badge>(
                predicate: #Predicate { $0.userId == uid }
            )
            var existing = try modelContext.fetch(descriptor)

            // Seed any missing badge types so the badge/award pipeline has rows to
            // unlock. (Previously no badges were ever created, so the whole badge,
            // streak-freeze, and rating-prompt flow was dead.)
            let existingTypes = Set(existing.map(\.type))
            for type in BadgeType.allCases where !existingTypes.contains(type) {
                let badge = Badge(userId: uid, type: type)
                modelContext.insert(badge)
                existing.append(badge)
            }
            if existingTypes.count != BadgeType.allCases.count {
                try? modelContext.save()
            }

            badges = existing
                .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
            unlockedBadges = badges.filter { $0.isUnlocked }
        } catch {
            print("[GamificationService] Error loading badges: \(error)")
        }
    }

    // MARK: - Events

    /// The single entry point for a saved sleep log. Awards XP, advances quests,
    /// updates lifetime counters, and re-checks badges. `isFirstLogOfNight` is
    /// false when the user edits an already-logged night — edits never re-award.
    func recordSleepLogged(hitTarget: Bool, energyRating: Int, isFirstLogOfNight: Bool, currentStreak: Int) {
        guard isFirstLogOfNight, let profile = gamificationProfile else { return }

        lastKnownStreak = max(lastKnownStreak, currentStreak)

        addXP(25, reason: "Logged sleep")
        if hitTarget {
            addXP(25, reason: "Hit bedtime target")
            profile.hitNightCount += 1
        }
        if energyRating >= 4 {
            addXP(15, reason: "High energy score")
        }
        if energyRating >= 5 {
            profile.highEnergyDayCount += 1
        }

        advanceQuests { objective in
            switch objective {
            case .logSleepQuality:
                return true
            case .hitBedtime, .completeBedtimeStreak3, .completeBedtimeStreak7, .weekOfConsistency:
                return hitTarget
            case .energyScore80Plus:
                return energyRating >= 4
            case .streakMilestone:
                return currentStreak >= 10
            case .completeWindDown, .completeWindDownStreak3, .completedRoutine:
                return false
            }
        }

        checkAndUnlockBadges(streakDays: currentStreak)
        saveChanges()
    }

    /// Marks tonight's wind-down routine as done. Guarded to once per calendar
    /// day so repeated taps can't farm quest progress.
    /// - Returns: `true` if the completion counted (first time today).
    @discardableResult
    func recordRoutineCompleted() -> Bool {
        guard let profile = gamificationProfile else { return false }
        if let last = profile.lastRoutineCompletedDay, Calendar.current.isDateInToday(last) {
            return false
        }
        profile.lastRoutineCompletedDay = Date()

        addXP(15, reason: "Completed wind-down routine")
        advanceQuests { objective in
            switch objective {
            case .completeWindDown, .completeWindDownStreak3, .completedRoutine:
                return true
            default:
                return false
            }
        }
        checkAndUnlockBadges()
        saveChanges()
        return true
    }

    /// Lets the streak pipeline (recalculations, freezes) push badge checks.
    func updateStreak(_ streak: Int) {
        lastKnownStreak = streak
        checkAndUnlockBadges(streakDays: streak)
    }

    // MARK: - XP & Level Management

    func addXP(_ amount: Int, reason: String = "") {
        guard let profile = gamificationProfile else { return }

        let oldLevel = profile.currentLevel
        profile.addXP(amount)

        if profile.currentLevel != oldLevel {
            lastLevelUpLevel = profile.currentLevel
            showLevelUpAnimation = true
            HapticFeedbackEngine.shared.triggerLevelUp()

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.0))
                self.showLevelUpAnimation = false
            }

            // A level change can unlock level badges.
            checkAndUnlockBadges()
        }

        saveChanges()
    }

    // MARK: - Quest Management

    /// Advances every live, incomplete quest whose objective the predicate
    /// matches; completed quests award their XP exactly once (`xpRewarded`).
    private func advanceQuests(matching shouldAdvance: (QuestObjective) -> Bool) {
        guard let profile = gamificationProfile else { return }

        for quest in dailyQuests + weeklyQuests where !quest.isCompleted {
            guard shouldAdvance(quest.objective) else { continue }
            quest.advance()
            if quest.isCompleted && !quest.xpRewarded {
                quest.xpRewarded = true
                profile.completedQuestCount += 1
                completedQuestThisSession = quest
                HapticFeedbackEngine.shared.triggerQuestCompletion()
                addXP(quest.objective.xpReward, reason: "Quest complete")
            }
        }
    }

    private func regenerateExpiredQuests() {
        guard let profile = gamificationProfile else { return }

        dailyQuests.removeAll { isQuestExpired($0) }

        let dailyQuestGoal = 3
        if dailyQuests.count < dailyQuestGoal {
            let questTemplates: [QuestObjective] = [
                .hitBedtime,
                .completeWindDown,
                .logSleepQuality,
                .completedRoutine,
                .energyScore80Plus
            ]

            // Rotate the template window by day so quest variety changes daily
            // instead of always serving the same first three.
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
            let active = Set(dailyQuests.map(\.objective))
            var offset = 0
            while dailyQuests.count < dailyQuestGoal && offset < questTemplates.count {
                let objective = questTemplates[(dayOfYear + offset) % questTemplates.count]
                offset += 1
                guard !active.contains(objective) else { continue }
                let quest = Quest(userId: profile.userId, objective: objective, type: .daily)
                modelContext.insert(quest)
                dailyQuests.append(quest)
            }
        }

        if weeklyQuests.isEmpty {
            let weeklyObjectives: [QuestObjective] = [
                .completeBedtimeStreak7,
                .weekOfConsistency,
                .energyScore80Plus,
                .completedRoutine
            ]

            for objective in weeklyObjectives.shuffled().prefix(2) {
                let quest = Quest(userId: profile.userId, objective: objective, type: .weekly, targetProgress: 7)
                modelContext.insert(quest)
                weeklyQuests.append(quest)
            }
        }

        saveChanges()
    }

    private func isQuestExpired(_ quest: Quest) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        if quest.type == .daily {
            return !calendar.isDateInToday(quest.resetAt)
        } else {
            // Weekly quests live for 7 days from creation. Using a day-count
            // delta is timezone- and DST-stable (unlike comparing weekday
            // numbers, which broke across week boundaries and time changes).
            let daysSinceReset = calendar.dateComponents([.day], from: quest.resetAt.startOfDay, to: now.startOfDay).day ?? 0
            return daysSinceReset >= 7
        }
    }

    // MARK: - Badge Management

    func checkAndUnlockBadges(streakDays: Int? = nil) {
        if let streakDays { lastKnownStreak = max(lastKnownStreak, streakDays) }

        // Unlocking a badge awards XP, which can level up, which can unlock the
        // level badges — run passes until nothing new unlocks.
        if badgeCheckInProgress {
            needsBadgeRecheck = true
            return
        }
        badgeCheckInProgress = true
        repeat {
            needsBadgeRecheck = false
            runBadgeUnlockPass()
        } while needsBadgeRecheck
        badgeCheckInProgress = false

        saveChanges()
    }

    private func runBadgeUnlockPass() {
        guard let profile = gamificationProfile else { return }

        for badge in badges where !badge.isUnlocked {
            guard shouldUnlock(badge.type, profile: profile) else { continue }

            badge.isUnlocked = true
            badge.unlockedAt = Date()
            unlockedBadges.append(badge)
            unlockedBadgeThisSession = badge
            HapticFeedbackEngine.shared.triggerBadgeUnlock()

            // Award a streak-freeze token at meaningful streak milestones so
            // the user has a safety net to protect long streaks (capped at 3).
            switch badge.type {
            case .week1Streak, .week2Streak, .month1Streak, .month3Streak:
                profile.streakFreezeTokens = min(3, profile.streakFreezeTokens + 1)
            default:
                break
            }

            // Ask for an App Store rating at a genuine high point — a
            // meaningful streak badge. Throttled to once per app version.
            switch badge.type {
            case .week1Streak, .month1Streak, .consistencyKing:
                RatingService.requestReviewAfterMilestone()
            default:
                break
            }

            addXP(100, reason: "Badge unlocked")
        }
    }

    private func shouldUnlock(_ type: BadgeType, profile: GamificationProfile) -> Bool {
        let streak = lastKnownStreak
        switch type {
        case .firstBedtime: return profile.hitNightCount >= 1 || streak >= 1
        case .week1Streak: return streak >= 7
        case .week2Streak: return streak >= 14
        case .month1Streak: return streak >= 30
        case .month3Streak: return streak >= 90
        case .month6Streak: return streak >= 180
        case .year1Streak: return streak >= 365
        case .perfectWeek: return streak >= 7
        case .level3: return profile.currentLevel.rawValue >= 3
        case .level5: return profile.currentLevel.rawValue >= 5
        case .allQuests: return profile.completedQuestCount >= 50
        case .energyChampion: return profile.highEnergyDayCount >= 10
        case .consistencyKing: return profile.hitNightCount >= 100
        }
    }

    // MARK: - Persistence

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("[GamificationService] Error saving gamification data: \(error)")
        }
    }
}
