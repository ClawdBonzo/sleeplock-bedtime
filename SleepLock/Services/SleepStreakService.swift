import Foundation
import SwiftData
import SwiftUI

// MARK: - Streak Calculator

/// The single source of truth for streak math, shared by the dashboard, the
/// badge/milestone pipeline, and the widget snapshot. Frozen day-keys count as
/// hits everywhere, so a protected streak is protected consistently.
enum StreakCalculator {
    /// Day-keys (yyyy-MM-dd) that count as a hit: nights logged on-target plus
    /// freeze-protected days.
    static func hitDayKeys(entries: [SleepLogEntry], frozenKeys: Set<String>) -> Set<String> {
        var keys = frozenKeys
        for entry in entries where entry.hitTarget {
            keys.insert(GamificationProfile.dayKey(for: entry.date))
        }
        return keys
    }

    /// Consecutive hit days ending today (or yesterday when today isn't logged).
    static func currentStreak(entries: [SleepLogEntry], frozenKeys: Set<String>, asOf: Date = Date()) -> Int {
        let hits = hitDayKeys(entries: entries, frozenKeys: frozenKeys)
        guard !hits.isEmpty else { return 0 }

        let calendar = Calendar.current
        var expectedDate = asOf.startOfDay

        // If today isn't a hit yet, the streak can still be alive from yesterday.
        if !hits.contains(GamificationProfile.dayKey(for: expectedDate)) {
            expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
        }

        var streak = 0
        while hits.contains(GamificationProfile.dayKey(for: expectedDate)) {
            streak += 1
            expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
        }
        return streak
    }

    /// Longest run of consecutive hit days anywhere in history. Duplicate
    /// same-day entries collapse to one day.
    static func longestStreak(entries: [SleepLogEntry], frozenKeys: Set<String>) -> Int {
        let calendar = Calendar.current
        var hitDays = Set<Date>()
        for entry in entries where entry.hitTarget {
            hitDays.insert(entry.date.startOfDay)
        }
        // Frozen keys are stored as strings; resolve them to day starts.
        let keyed = Set(hitDays.map { GamificationProfile.dayKey(for: $0) })
        for key in frozenKeys where !keyed.contains(key) {
            let parts = key.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { continue }
            var comps = DateComponents()
            comps.year = parts[0]; comps.month = parts[1]; comps.day = parts[2]
            if let day = calendar.date(from: comps) {
                hitDays.insert(day.startOfDay)
            }
        }
        guard !hitDays.isEmpty else { return 0 }

        var longest = 0
        var current = 0
        var lastDay: Date?
        for day in hitDays.sorted() {
            if let last = lastDay,
               calendar.dateComponents([.day], from: last, to: day).day == 1 {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            lastDay = day
        }
        return longest
    }
}

// MARK: - Sleep Streak Service

@Observable
@MainActor
final class SleepStreakService {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var energyScore: Double = 0
    var todayLogged: Bool = false
    /// Whether today's log actually hit the bedtime target (≠ merely logged).
    var todayHitTarget: Bool = false
    var weeklyConsistency: Double = 0
    /// Distinct nights logged (duplicate same-day entries count once).
    var totalNightsLogged: Int = 0
    /// Banked streak-freeze tokens (mirrored from GamificationProfile for the UI).
    var streakFreezeTokens: Int = 0
    /// True when yesterday broke a live streak and a freeze token could save it.
    /// The dashboard surfaces this as a user choice instead of auto-spending.
    var pendingFreezeOffer: Bool = false

    private var modelContext: ModelContext?

    func configure(with context: ModelContext) {
        self.modelContext = context
        recalculate()
    }

    func recalculate() {
        guard let context = modelContext else { return }

        // Bounded: two years of nightly logs is more than any streak/stat needs.
        var descriptor = FetchDescriptor<SleepLogEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 730

        guard let entries = try? context.fetch(descriptor) else { return }

        let profile = (try? context.fetch(FetchDescriptor<GamificationProfile>()))?.first

        evaluateFreezeOffer(entries: entries, profile: profile)
        let frozen = Set(profile?.frozenDateKeys ?? [])
        streakFreezeTokens = profile?.streakFreezeTokens ?? 0

        currentStreak = StreakCalculator.currentStreak(entries: entries, frozenKeys: frozen)
        longestStreak = StreakCalculator.longestStreak(entries: entries, frozenKeys: frozen)
        energyScore = calculateEnergyScore(from: entries)

        let todayEntries = entries.filter { $0.date.isToday }
        todayLogged = !todayEntries.isEmpty
        todayHitTarget = todayEntries.contains { $0.hitTarget }

        totalNightsLogged = Set(entries.map { GamificationProfile.dayKey(for: $0.date) }).count
        weeklyConsistency = calculateWeeklyConsistency(entries: entries, frozenKeys: frozen)
    }

    // MARK: - Streak Freeze Offer

    /// Detects the "yesterday broke a live streak" situation and offers a
    /// freeze instead of silently spending the token. `lastStreakEvalDay`
    /// records that the user has decided (either way) for the current day.
    private func evaluateFreezeOffer(entries: [SleepLogEntry], profile: GamificationProfile?) {
        pendingFreezeOffer = false
        guard let profile, profile.streakFreezeTokens > 0 else { return }
        let calendar = Calendar.current
        let today = Date().startOfDay

        if let last = profile.lastStreakEvalDay, calendar.isDate(last, inSameDayAs: today) { return }

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let dayBefore = calendar.date(byAdding: .day, value: -2, to: today) else { return }
        let yesterdayKey = GamificationProfile.dayKey(for: yesterday)
        guard !profile.frozenDateKeys.contains(yesterdayKey) else { return }

        let hits = StreakCalculator.hitDayKeys(entries: entries, frozenKeys: Set(profile.frozenDateKeys))

        // Offer only when yesterday is a miss AND there was a live streak to save.
        guard !hits.contains(yesterdayKey),
              hits.contains(GamificationProfile.dayKey(for: dayBefore)) else { return }

        pendingFreezeOffer = true
    }

    /// Spends one token to protect yesterday. Called from the dashboard offer.
    func acceptFreezeOffer() {
        guard let context = modelContext,
              let profile = (try? context.fetch(FetchDescriptor<GamificationProfile>()))?.first,
              profile.streakFreezeTokens > 0,
              let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date().startOfDay)
        else { pendingFreezeOffer = false; return }

        let key = GamificationProfile.dayKey(for: yesterday)
        if !profile.frozenDateKeys.contains(key) {
            profile.frozenDateKeys.append(key)
            profile.streakFreezeTokens -= 1
        }
        profile.lastStreakEvalDay = Date().startOfDay
        try? context.save()
        pendingFreezeOffer = false
        recalculate()
    }

    /// Declines the offer; the streak resets naturally and we don't re-ask today.
    func declineFreezeOffer() {
        guard let context = modelContext,
              let profile = (try? context.fetch(FetchDescriptor<GamificationProfile>()))?.first
        else { pendingFreezeOffer = false; return }

        profile.lastStreakEvalDay = Date().startOfDay
        try? context.save()
        pendingFreezeOffer = false
        recalculate()
    }

    // MARK: - Stats

    /// Average of the last 7 calendar days' energy ratings (one per day, latest
    /// entry wins) — not the last 7 entries, which could span weeks.
    private func calculateEnergyScore(from entries: [SleepLogEntry]) -> Double {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -7, to: Date().startOfDay) else { return 0 }

        var seenDays = Set<String>()
        var ratings: [Int] = []
        for entry in entries where entry.date >= cutoff {
            let key = GamificationProfile.dayKey(for: entry.date)
            if seenDays.insert(key).inserted {
                ratings.append(entry.morningEnergyRating)
            }
        }
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.reduce(0, +)) / Double(ratings.count) / 5.0 * 100
    }

    /// Hits ÷ 7 over the most recent 7-day window (ending today if logged,
    /// otherwise yesterday) — a true consistency rate, not hits ÷ logged nights.
    private func calculateWeeklyConsistency(entries: [SleepLogEntry], frozenKeys: Set<String>) -> Double {
        let calendar = Calendar.current
        let hits = StreakCalculator.hitDayKeys(entries: entries, frozenKeys: frozenKeys)

        var windowEnd = Date().startOfDay
        let todayKey = GamificationProfile.dayKey(for: windowEnd)
        let loggedToday = entries.contains { $0.date.isToday }
        if !loggedToday && !hits.contains(todayKey) {
            windowEnd = calendar.date(byAdding: .day, value: -1, to: windowEnd) ?? windowEnd
        }

        var hitCount = 0
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: windowEnd) else { continue }
            if hits.contains(GamificationProfile.dayKey(for: day)) {
                hitCount += 1
            }
        }
        return Double(hitCount) / 7.0 * 100
    }
}
