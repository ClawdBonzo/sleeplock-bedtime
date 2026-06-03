import Foundation
import SwiftData

@Observable
@MainActor
final class GamificationService {
    static let shared = GamificationService()

    private let modelContext: ModelContext?

    private(set) var gamificationProfile: GamificationProfile?
    private(set) var dailyQuests: [Quest] = []
    private(set) var weeklyQuests: [Quest] = []
    private(set) var badges: [Badge] = []
    private(set) var unlockedBadges: [Badge] = []

    private(set) var lastLevelUpLevel: SleepLevel?
    private(set) var showLevelUpAnimation = false
    private(set) var completedQuestThisSession: Quest?
    private(set) var unlockedBadgeThisSession: Badge?

    /// Total completed quests across daily + weekly. Computed once per access
    /// instead of filtering twice inside a view body on every re-render.
    var completedQuestCount: Int {
        dailyQuests.reduce(0) { $0 + ($1.isCompleted ? 1 : 0) }
            + weeklyQuests.reduce(0) { $0 + ($1.isCompleted ? 1 : 0) }
    }

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            loadGamificationData()
        }
    }

    // MARK: - Initialization & Loading

    private func loadGamificationData() {
        guard let modelContext else { return }

        do {
            let descriptor = FetchDescriptor<GamificationProfile>()
            let profiles = try modelContext.fetch(descriptor)

            if let profile = profiles.first {
                self.gamificationProfile = profile
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

    private func loadQuests() {
        guard let modelContext, let profile = gamificationProfile else { return }

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
        guard let modelContext, let profile = gamificationProfile else { return }

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
        }

        saveChanges()
    }

    // MARK: - Quest Management

    private func regenerateExpiredQuests() {
        guard let modelContext, let profile = gamificationProfile else { return }

        dailyQuests.removeAll { isQuestExpired($0) }

        let existingDailyCount = dailyQuests.count
        let dailyQuestGoal = 3

        if existingDailyCount < dailyQuestGoal {
            let questTemplates: [QuestObjective] = [
                .hitBedtime,
                .completeWindDown,
                .logSleepQuality,
                .completedRoutine,
                .energyScore80Plus
            ]

            for i in 0..<(dailyQuestGoal - existingDailyCount) {
                if i < questTemplates.count {
                    let quest = Quest(userId: profile.userId, objective: questTemplates[i], type: .daily)
                    modelContext.insert(quest)
                    dailyQuests.append(quest)
                }
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

    func completeQuest(_ quest: Quest) {
        guard let profile = gamificationProfile else { return }

        quest.isCompleted = true
        quest.completedAt = Date()

        let xpReward = quest.objective.xpReward
        addXP(xpReward)

        completedQuestThisSession = quest
        HapticFeedbackEngine.shared.triggerQuestCompletion()

        saveChanges()
    }

    // MARK: - Badge Management

    func checkAndUnlockBadges(streakDays: Int? = nil, level: SleepLevel? = nil, xpTotal: Int? = nil) {
        for badge in badges where !badge.isUnlocked {
            var shouldUnlock = false

            if let requiredStreak = streakDays {
                shouldUnlock = shouldUnlock || (requiredStreak >= 1 && badge.type == .firstBedtime) ||
                    (requiredStreak >= 7 && badge.type == .week1Streak) ||
                    (requiredStreak >= 14 && badge.type == .week2Streak) ||
                    (requiredStreak >= 30 && badge.type == .month1Streak) ||
                    (requiredStreak >= 90 && badge.type == .month3Streak) ||
                    (requiredStreak >= 180 && badge.type == .month6Streak) ||
                    (requiredStreak >= 365 && badge.type == .year1Streak) ||
                    (requiredStreak >= 7 && badge.type == .perfectWeek) ||
                    (requiredStreak >= 100 && badge.type == .consistencyKing)
            }

            if let currentLevel = level {
                shouldUnlock = shouldUnlock || (currentLevel == .restfulDreamer && badge.type == .level3) ||
                    (currentLevel == .sleepChampion && badge.type == .level5)
            }

            if shouldUnlock {
                badge.isUnlocked = true
                badge.unlockedAt = Date()
                HapticFeedbackEngine.shared.triggerBadgeUnlock()
                unlockedBadgeThisSession = badge
                addXP(100)
                unlockedBadges.append(badge)

                // Award a streak-freeze token at meaningful streak milestones so
                // the user has a safety net to protect long streaks (capped at 3).
                switch badge.type {
                case .week1Streak, .week2Streak, .month1Streak, .month3Streak:
                    if let p = gamificationProfile {
                        p.streakFreezeTokens = min(3, p.streakFreezeTokens + 1)
                    }
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
            }
        }

        saveChanges()
    }

    // MARK: - Persistence

    private func saveChanges() {
        guard let modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("[GamificationService] Error saving gamification data: \(error)")
        }
    }
}
