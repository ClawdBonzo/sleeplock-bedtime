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

        // Current streak
        currentStreak = calculateCurrentStreak(from: entries)
        longestStreak = calculateLongestStreak(from: entries)
        energyScore = calculateEnergyScore(from: entries)
        todayLogged = entries.first?.date.isToday ?? false
        weeklyConsistency = calculateWeeklyConsistency(from: entries)
    }

    private func calculateCurrentStreak(from entries: [SleepLogEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }

        var streak = 0
        let calendar = Calendar.current
        var expectedDate = Date().startOfDay

        // If today isn't logged yet, start from yesterday
        if !(entries.first?.date.isToday ?? false) {
            expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
        }

        for entry in entries {
            let entryDay = entry.date.startOfDay
            if calendar.isDate(entryDay, inSameDayAs: expectedDate) && entry.hitTarget {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else if calendar.isDate(entryDay, inSameDayAs: expectedDate) {
                break // Logged but didn't hit target
            } else {
                break // Gap in logging
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
