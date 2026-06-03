import Foundation
import SwiftData
import SwiftUI

@Observable
final class SleepStreakService {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var energyScore: Double = 0
    var todayLogged: Bool = false
    var weeklyConsistency: Double = 0
    /// Banked streak-freeze tokens (mirrored from GamificationProfile for the UI).
    var streakFreezeTokens: Int = 0

    private var modelContext: ModelContext?

    func configure(with context: ModelContext) {
        self.modelContext = context
        recalculate()
    }

    func recalculate() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<SleepLogEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let entries = try? context.fetch(descriptor) else { return }

        let profile = (try? context.fetch(FetchDescriptor<GamificationProfile>()))?.first

        // Possibly spend a freeze token to protect yesterday, then read the set
        // of protected day-keys for the streak walk.
        evaluateStreakFreeze(entries: entries, profile: profile, context: context)
        let frozen = Set(profile?.frozenDateKeys ?? [])
        streakFreezeTokens = profile?.streakFreezeTokens ?? 0

        // Current streak
        currentStreak = calculateCurrentStreak(from: entries, frozenKeys: frozen)
        longestStreak = calculateLongestStreak(from: entries)
        energyScore = calculateEnergyScore(from: entries)
        todayLogged = entries.first?.date.isToday ?? false
        weeklyConsistency = calculateWeeklyConsistency(from: entries)
    }

    /// Auto-consumes one freeze token to protect *yesterday* when the user has a
    /// live streak that an off-night would otherwise break. Runs at most once per
    /// calendar day (guarded by `lastStreakEvalDay`) so it can't double-spend.
    private func evaluateStreakFreeze(entries: [SleepLogEntry], profile: GamificationProfile?, context: ModelContext) {
        guard let profile, profile.streakFreezeTokens > 0 else { return }
        let calendar = Calendar.current
        let today = Date().startOfDay

        if let last = profile.lastStreakEvalDay, calendar.isDate(last, inSameDayAs: today) { return }

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }
        let yesterdayKey = GamificationProfile.dayKey(for: yesterday)

        if profile.frozenDateKeys.contains(yesterdayKey) {
            profile.lastStreakEvalDay = today
            try? context.save()
            return
        }

        // Yesterday breaks a streak only if there's no hit entry for it.
        let yesterdayHit = entries.contains { calendar.isDate($0.date.startOfDay, inSameDayAs: yesterday) && $0.hitTarget }
        guard !yesterdayHit else {
            profile.lastStreakEvalDay = today
            try? context.save()
            return
        }

        // Only worth a token if the day *before* yesterday was itself a hit (or
        // frozen) — i.e. there was a live streak to save.
        guard let dayBefore = calendar.date(byAdding: .day, value: -2, to: today) else { return }
        let dayBeforeKey = GamificationProfile.dayKey(for: dayBefore)
        let dayBeforeProtected = profile.frozenDateKeys.contains(dayBeforeKey)
            || entries.contains { calendar.isDate($0.date.startOfDay, inSameDayAs: dayBefore) && $0.hitTarget }

        if dayBeforeProtected {
            profile.frozenDateKeys.append(yesterdayKey)
            profile.streakFreezeTokens -= 1
        }
        profile.lastStreakEvalDay = today
        try? context.save()
    }

    private func calculateCurrentStreak(from entries: [SleepLogEntry], frozenKeys: Set<String>) -> Int {
        guard !entries.isEmpty || !frozenKeys.isEmpty else { return 0 }

        let calendar = Calendar.current
        var expectedDate = Date().startOfDay

        // Index entries by day-key for O(1) lookups while walking backwards.
        var hitByKey: [String: Bool] = [:]
        for entry in entries {
            let key = GamificationProfile.dayKey(for: entry.date)
            hitByKey[key] = (hitByKey[key] ?? false) || entry.hitTarget
        }

        // If today isn't logged yet, start from yesterday.
        if !(entries.first?.date.isToday ?? false) {
            expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
        }

        var streak = 0
        while true {
            let key = GamificationProfile.dayKey(for: expectedDate)
            let dayCounts = (hitByKey[key] == true) || frozenKeys.contains(key)
            if dayCounts {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else {
                break // Missed/un-frozen day ends the streak.
            }
        }

        return streak
    }

    private func calculateLongestStreak(from entries: [SleepLogEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }

        let sorted = entries.sorted { $0.date < $1.date }
        var longest = 0
        var current = 0
        let calendar = Calendar.current
        var lastDate: Date?

        for entry in sorted where entry.hitTarget {
            if let last = lastDate {
                let dayDiff = calendar.dateComponents([.day], from: last.startOfDay, to: entry.date.startOfDay).day ?? 0
                if dayDiff == 1 {
                    current += 1
                } else {
                    current = 1
                }
            } else {
                current = 1
            }
            longest = max(longest, current)
            lastDate = entry.date
        }

        return longest
    }

    private func calculateEnergyScore(from entries: [SleepLogEntry]) -> Double {
        let recent = Array(entries.prefix(7))
        guard !recent.isEmpty else { return 0 }

        let totalEnergy = recent.reduce(0) { $0 + $1.morningEnergyRating }
        return (Double(totalEnergy) / Double(recent.count)) / 5.0 * 100
    }

    private func calculateWeeklyConsistency(from entries: [SleepLogEntry]) -> Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let thisWeek = entries.filter { $0.date >= weekAgo }
        guard !thisWeek.isEmpty else { return 0 }

        let onTarget = thisWeek.filter { $0.hitTarget }.count
        return Double(onTarget) / Double(thisWeek.count) * 100
    }
}
