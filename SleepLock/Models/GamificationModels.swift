import Foundation
import SwiftData

// MARK: - Sleep Level Progression

enum SleepLevel: Int, Codable, CaseIterable {
    case nightOwl = 1
    case sleepyHead = 2
    case restfulDreamer = 3
    case sleepMaster = 4
    case sleepChampion = 5
    case sleepKing = 6

    var displayName: String {
        switch self {
        case .nightOwl: return "Night Owl"
        case .sleepyHead: return "Sleepy Head"
        case .restfulDreamer: return "Restful Dreamer"
        case .sleepMaster: return "Sleep Master"
        case .sleepChampion: return "Sleep Champion"
        case .sleepKing: return "Sleep King"
        }
    }

    var emoji: String {
        switch self {
        case .nightOwl: return "🦉"
        case .sleepyHead: return "😴"
        case .restfulDreamer: return "☁️"
        case .sleepMaster: return "⭐"
        case .sleepChampion: return "🔥"
        case .sleepKing: return "👑"
        }
    }

    var sfSymbol: String {
        switch self {
        case .nightOwl: return "moon.stars.fill"
        case .sleepyHead: return "moon.zzz.fill"
        case .restfulDreamer: return "cloud.fill"
        case .sleepMaster: return "star.fill"
        case .sleepChampion: return "flame.fill"
        case .sleepKing: return "crown.fill"
        }
    }

    var xpRequired: Int {
        switch self {
        case .nightOwl: return 0
        case .sleepyHead: return 100
        case .restfulDreamer: return 300
        case .sleepMaster: return 600
        case .sleepChampion: return 1000
        case .sleepKing: return 1500
        }
    }

    var nextLevel: SleepLevel? {
        return SleepLevel(rawValue: self.rawValue + 1)
    }
}

// MARK: - XP Progress Profile

@Model
final class GamificationProfile {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var totalXP: Int
    var currentLevel: SleepLevel
    var levelUpCount: Int

    var xpInCurrentLevel: Int

    var xpToNextLevel: Int {
        currentLevel.nextLevel?.xpRequired ?? 0
    }

    var progressToNextLevel: Double {
        guard xpToNextLevel > 0 else { return 1.0 }
        return Double(xpInCurrentLevel) / Double(xpToNextLevel)
    }

    var createdAt: Date
    var lastXPGainDate: Date

    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.totalXP = 0
        self.currentLevel = .nightOwl
        self.levelUpCount = 0
        self.xpInCurrentLevel = 0
        self.createdAt = Date()
        self.lastXPGainDate = Date()
    }

    func addXP(_ amount: Int) {
        totalXP += amount
        xpInCurrentLevel += amount

        while let nextLevel = currentLevel.nextLevel,
              xpInCurrentLevel >= nextLevel.xpRequired {
            xpInCurrentLevel -= nextLevel.xpRequired
            currentLevel = nextLevel
            levelUpCount += 1
        }

        lastXPGainDate = Date()
    }
}

// MARK: - Quest System

enum QuestType: String, Codable {
    case daily
    case weekly
}

enum QuestObjective: String, Codable {
    case hitBedtime = "Hit bedtime"
    case completeBedtimeStreak3 = "Hit bedtime 3 times"
    case completeBedtimeStreak7 = "Hit bedtime 7 times"
    case completeWindDown = "Complete wind-down"
    case completeWindDownStreak3 = "Complete wind-down 3 times"
    case logSleepQuality = "Log sleep quality"
    case energyScore80Plus = "Reach 80+ energy"
    case streakMilestone = "10-day streak"
    case completedRoutine = "Complete routine"
    case weekOfConsistency = "Perfect week"

    var displayText: String {
        return self.rawValue
    }

    var xpReward: Int {
        switch self {
        case .hitBedtime, .completeWindDown, .logSleepQuality, .completedRoutine:
            return 25
        case .completeBedtimeStreak3, .completeWindDownStreak3, .energyScore80Plus:
            return 50
        case .completeBedtimeStreak7, .streakMilestone:
            return 75
        case .weekOfConsistency:
            return 100
        }
    }

    var emoji: String {
        switch self {
        case .hitBedtime, .completeBedtimeStreak3, .completeBedtimeStreak7:
            return "🛏️"
        case .completeWindDown, .completeWindDownStreak3:
            return "🧘"
        case .logSleepQuality:
            return "⭐"
        case .energyScore80Plus:
            return "⚡"
        case .streakMilestone, .weekOfConsistency:
            return "🔥"
        case .completedRoutine:
            return "✅"
        }
    }

    var sfSymbol: String {
        switch self {
        case .hitBedtime, .completeBedtimeStreak3, .completeBedtimeStreak7:
            return "bed.double.fill"
        case .completeWindDown, .completeWindDownStreak3:
            return "moon.zzz.fill"
        case .logSleepQuality:
            return "star.fill"
        case .energyScore80Plus:
            return "bolt.fill"
        case .streakMilestone, .weekOfConsistency:
            return "flame.fill"
        case .completedRoutine:
            return "checklist"
        }
    }
}

@Model
final class Quest {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID
    var objective: QuestObjective
    var type: QuestType
    var progress: Int = 0
    var targetProgress: Int = 1
    var isCompleted: Bool = false
    var completedAt: Date?
    var xpRewarded: Bool = false

    var createdAt: Date = Date()
    var resetAt: Date = Date()

    init(userId: UUID, objective: QuestObjective, type: QuestType, targetProgress: Int = 1) {
        self.userId = userId
        self.objective = objective
        self.type = type
        self.targetProgress = targetProgress
    }

    var progress_percentage: Double {
        guard targetProgress > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(targetProgress))
    }

    func advance(_ amount: Int = 1) {
        guard !isCompleted else { return }
        progress = min(progress + amount, targetProgress)
        if progress >= targetProgress && !isCompleted {
            isCompleted = true
            completedAt = Date()
        }
    }
}

// MARK: - Badge System

enum BadgeType: String, Codable, CaseIterable {
    case firstBedtime = "First Step"
    case week1Streak = "Week Wonder"
    case week2Streak = "Fortnight Fighter"
    case month1Streak = "Monthly Master"
    case month3Streak = "Tri-Monthly Titan"
    case month6Streak = "Six-Month Sage"
    case year1Streak = "Yearly Yogi"
    case perfectWeek = "Perfect Week"
    case level3 = "Rising Star"
    case level5 = "Sleep Sage"
    case allQuests = "Quest Conqueror"
    case energyChampion = "Energy Champion"
    case consistencyKing = "Consistency King"

    var displayName: String {
        return self.rawValue
    }

    var description: String {
        switch self {
        case .firstBedtime: return "Hit your first bedtime goal"
        case .week1Streak: return "Maintain a 7-day streak"
        case .week2Streak: return "Maintain a 14-day streak"
        case .month1Streak: return "Maintain a 30-day streak"
        case .month3Streak: return "Maintain a 90-day streak"
        case .month6Streak: return "Maintain a 180-day streak"
        case .year1Streak: return "Maintain a 365-day streak"
        case .perfectWeek: return "Hit bedtime 7 days straight"
        case .level3: return "Reach level 3"
        case .level5: return "Reach level 5"
        case .allQuests: return "Complete 50 quests"
        case .energyChampion: return "Achieve 90+ energy 10 times"
        case .consistencyKing: return "Hit bedtime 100 times"
        }
    }

    var sfSymbol: String {
        switch self {
        case .firstBedtime: return "moon.stars.fill"
        case .week1Streak, .week2Streak, .month1Streak: return "flame.fill"
        case .month3Streak, .month6Streak, .year1Streak: return "crown.fill"
        case .perfectWeek: return "sparkles"
        case .level3, .level5: return "star.fill"
        case .allQuests: return "scope"
        case .energyChampion: return "bolt.fill"
        case .consistencyKing: return "diamond.fill"
        }
    }

    var emoji: String {
        switch self {
        case .firstBedtime: return "🌙"
        case .week1Streak, .week2Streak, .month1Streak: return "🔥"
        case .month3Streak, .month6Streak, .year1Streak: return "👑"
        case .perfectWeek: return "💫"
        case .level3, .level5: return "⭐"
        case .allQuests: return "🎯"
        case .energyChampion: return "⚡"
        case .consistencyKing: return "💎"
        }
    }
}

@Model
final class Badge {
    @Attribute(.unique) var id: UUID = UUID()
    var userId: UUID
    var type: BadgeType
    var unlockedAt: Date?
    var isUnlocked: Bool = false

    init(userId: UUID, type: BadgeType) {
        self.userId = userId
        self.type = type
    }
}
