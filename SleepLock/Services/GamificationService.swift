import Foundation
import SwiftData

@Observable
final class GamificationService: @unchecked Sendable {
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
            let descriptor = FetchDescriptor<Quest>()
            var allQuests = try modelContext.fetch(descriptor)
            allQuests = allQuests.filter { $0.userId == profile.userId }.sorted { $0.createdAt > $1.createdAt }

            dailyQuests = allQuests.filter { $0.type == .daily && !isQuestExpired($0) }
            weeklyQuests = allQuests.filter { $0.type == .weekly && !isQuestExpired($0) }

            regenerateExpiredQuests()
        } catch {
            print("[GamificationService] Error loading quests: \(error)")
        }
    }

    private func loadBadges() {
        guard let modelContext, let profile = gamificationProfile else { return }

        do {
            let descriptor = FetchDescriptor<Badge>()
            var allBadges = try modelContext.fetch(descriptor)
            badges = allBadges.filter { $0.userId == profile.userId }.sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
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

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
            let components = calendar.dateComponents([.weekday], from: quest.resetAt)
            let currentComponents = calendar.dateComponents([.weekday], from: now)
            return components.weekday != currentComponents.weekday || !calendar.isDate(quest.resetAt, inSameDayAs: now)
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
