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
        case .nightOwl: return String(localized: "Night Owl")
        case .sleepyHead: return String(localized: "Sleepy Head")
        case .restfulDreamer: return String(localized: "Restful Dreamer")
        case .sleepMaster: return String(localized: "Sleep Master")
        case .sleepChampion: return String(localized: "Sleep Champion")
        case .sleepKing: return String(localized: "Sleep King")
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

    /// XP needed to advance from the current level to the next. `xpRequired`
    /// values are cumulative totals, so the per-level cost is the delta.
    var xpToNextLevel: Int {
        guard let next = currentLevel.nextLevel else { return 0 }
        return next.xpRequired - currentLevel.xpRequired
    }

    var progressToNextLevel: Double {
        guard xpToNextLevel > 0 else { return 1.0 }
        return Double(xpInCurrentLevel) / Double(xpToNextLevel)
    }

    var createdAt: Date
    var lastXPGainDate: Date

    // MARK: Streak Freeze (forgiveness mechanic)
    /// Banked freeze tokens earned at streak milestones. One token auto-protects
    /// a single missed day so a long streak survives an off-night.
    var streakFreezeTokens: Int = 0
    /// `yyyy-MM-dd` keys for days a token protected. The streak calculation
    /// treats these days as "hit" even if the user missed or didn't log them.
    var frozenDateKeys: [String] = []
    /// Last calendar day we evaluated auto-freeze, so we consume at most one
    /// token per day regardless of how often the streak is recalculated.
    var lastStreakEvalDay: Date?

    // MARK: Lifetime counters (badge progress)
    /// Quests completed all-time — drives the "Quest Conqueror" badge.
    var completedQuestCount: Int = 0
    /// Days logged with a top energy rating — drives the "Energy Champion" badge.
    var highEnergyDayCount: Int = 0
    /// Nights that hit the bedtime target all-time — drives "Consistency King".
    var hitNightCount: Int = 0
    /// Last day the wind-down routine was marked complete (one credit per day).
    var lastRoutineCompletedDay: Date?

    init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.totalXP = 0
        self.currentLevel = .nightOwl
        self.levelUpCount = 0
        self.xpInCurrentLevel = 0
        self.createdAt = Date()
        self.lastXPGainDate = Date()
        self.streakFreezeTokens = 1 // start with one safety net
        self.frozenDateKeys = []
        self.lastStreakEvalDay = nil
    }

    /// Stable day key used by the streak-freeze bookkeeping.
    static func dayKey(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    func addXP(_ amount: Int) {
        totalXP += amount

        while let nextLevel = currentLevel.nextLevel,
              totalXP >= nextLevel.xpRequired {
            currentLevel = nextLevel
            levelUpCount += 1
        }

        xpInCurrentLevel = totalXP - currentLevel.xpRequired
        lastXPGainDate = Date()
    }

    /// Rebuilds `currentLevel`/`xpInCurrentLevel` from `totalXP`. Run once at
    /// load to repair profiles written by the old math, which treated the
    /// cumulative thresholds as per-level costs.
    func reconcileLevelFromTotalXP() {
        var level = SleepLevel.nightOwl
        while let next = level.nextLevel, totalXP >= next.xpRequired {
            level = next
        }
        currentLevel = level
        xpInCurrentLevel = totalXP - level.xpRequired
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
        switch self {
        case .hitBedtime: return String(localized: "Hit bedtime")
        case .completeBedtimeStreak3: return String(localized: "Hit bedtime 3 times")
        case .completeBedtimeStreak7: return String(localized: "Hit bedtime 7 times")
        case .completeWindDown: return String(localized: "Complete wind-down")
        case .completeWindDownStreak3: return String(localized: "Complete wind-down 3 times")
        case .logSleepQuality: return String(localized: "Log sleep quality")
        case .energyScore80Plus: return String(localized: "Reach 80+ energy")
        case .streakMilestone: return String(localized: "10-day streak")
        case .completedRoutine: return String(localized: "Complete routine")
        case .weekOfConsistency: return String(localized: "Perfect week")
        }
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
        switch self {
        case .firstBedtime: return String(localized: "First Step")
        case .week1Streak: return String(localized: "Week Wonder")
        case .week2Streak: return String(localized: "Fortnight Fighter")
        case .month1Streak: return String(localized: "Monthly Master")
        case .month3Streak: return String(localized: "Tri-Monthly Titan")
        case .month6Streak: return String(localized: "Six-Month Sage")
        case .year1Streak: return String(localized: "Yearly Yogi")
        case .perfectWeek: return String(localized: "Perfect Week")
        case .level3: return String(localized: "Rising Star")
        case .level5: return String(localized: "Sleep Sage")
        case .allQuests: return String(localized: "Quest Conqueror")
        case .energyChampion: return String(localized: "Energy Champion")
        case .consistencyKing: return String(localized: "Consistency King")
        }
    }

    var description: String {
        switch self {
        case .firstBedtime: return String(localized: "Hit your first bedtime goal")
        case .week1Streak: return String(localized: "Maintain a 7-day streak")
        case .week2Streak: return String(localized: "Maintain a 14-day streak")
        case .month1Streak: return String(localized: "Maintain a 30-day streak")
        case .month3Streak: return String(localized: "Maintain a 90-day streak")
        case .month6Streak: return String(localized: "Maintain a 180-day streak")
        case .year1Streak: return String(localized: "Maintain a 365-day streak")
        case .perfectWeek: return String(localized: "Hit bedtime 7 days straight")
        case .level3: return String(localized: "Reach level 3")
        case .level5: return String(localized: "Reach level 5")
        case .allQuests: return String(localized: "Complete 50 quests")
        case .energyChampion: return String(localized: "Achieve 90+ energy 10 times")
        case .consistencyKing: return String(localized: "Hit bedtime 100 times")
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
