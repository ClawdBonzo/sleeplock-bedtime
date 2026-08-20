import Foundation
import SwiftData
import SwiftUI

// MARK: - User Profile
@Model
final class UserProfile {
    var displayName: String
    var targetBedtime: Date
    var targetWakeTime: Date
    var sleepBlockers: [String]
    var currentSleepHabit: String
    var onboardingCompleted: Bool
    var createdAt: Date
    var notificationsEnabled: Bool
    var reminderMinutesBefore: Int

    init(
        displayName: String = "",
        targetBedtime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date(),
        targetWakeTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date(),
        sleepBlockers: [String] = [],
        currentSleepHabit: String = "",
        onboardingCompleted: Bool = false,
        createdAt: Date = Date(),
        notificationsEnabled: Bool = true,
        reminderMinutesBefore: Int = 30
    ) {
        self.displayName = displayName
        self.targetBedtime = targetBedtime
        self.targetWakeTime = targetWakeTime
        self.sleepBlockers = sleepBlockers
        self.currentSleepHabit = currentSleepHabit
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = createdAt
        self.notificationsEnabled = notificationsEnabled
        self.reminderMinutesBefore = reminderMinutesBefore
    }
}

// MARK: - Sleep Log Entry
@Model
final class SleepLogEntry {
    var date: Date
    var actualBedtime: Date
    var actualWakeTime: Date
    var targetBedtime: Date
    var morningEnergyRating: Int // 1-5
    var notes: String
    var hitTarget: Bool
    var sleepDurationMinutes: Int

    init(
        date: Date = Date(),
        actualBedtime: Date = Date(),
        actualWakeTime: Date = Date(),
        targetBedtime: Date = Date(),
        morningEnergyRating: Int = 3,
        notes: String = "",
        hitTarget: Bool = false
    ) {
        self.date = date
        self.actualBedtime = actualBedtime
        self.actualWakeTime = actualWakeTime
        self.targetBedtime = targetBedtime
        self.morningEnergyRating = morningEnergyRating
        self.notes = notes
        self.hitTarget = hitTarget

        self.sleepDurationMinutes = NightMath.durationMinutes(bedtime: actualBedtime, wakeTime: actualWakeTime)
    }

    /// Re-derives duration after bed/wake edits (e.g. updating today's log).
    func recalculateDuration() {
        sleepDurationMinutes = NightMath.durationMinutes(bedtime: actualBedtime, wakeTime: actualWakeTime)
    }
}

// MARK: - Routine Step
@Model
final class RoutineStep {
    var title: String
    var icon: String
    var durationMinutes: Int
    var sortOrder: Int
    var isEnabled: Bool
    var category: String

    init(
        title: String = "",
        icon: String = "moon",
        durationMinutes: Int = 10,
        sortOrder: Int = 0,
        isEnabled: Bool = true,
        category: String = "wind-down"
    ) {
        self.title = title
        self.icon = icon
        self.durationMinutes = durationMinutes
        self.sortOrder = sortOrder
        self.isEnabled = isEnabled
        self.category = category
    }
}

// MARK: - Sleep Blocker
struct SleepBlocker: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let description: String

    static let all: [SleepBlocker] = [
        SleepBlocker(id: "screens", title: "Screen Time", icon: "iphone", description: "Phone, tablet, TV before bed"),
        SleepBlocker(id: "caffeine", title: "Caffeine", icon: "cup.and.saucer.fill", description: "Coffee, tea, energy drinks"),
        SleepBlocker(id: "stress", title: "Stress & Anxiety", icon: "brain.head.profile", description: "Racing thoughts at night"),
        SleepBlocker(id: "irregular", title: "Irregular Schedule", icon: "clock.badge.questionmark", description: "Different times each night"),
        SleepBlocker(id: "noise", title: "Noise & Light", icon: "speaker.wave.3.fill", description: "Environment disturbances"),
        SleepBlocker(id: "eating", title: "Late Eating", icon: "fork.knife", description: "Heavy meals close to bed"),
        SleepBlocker(id: "exercise", title: "Late Exercise", icon: "figure.run", description: "Working out too close to bed"),
        SleepBlocker(id: "napping", title: "Long Naps", icon: "bed.double.fill", description: "Daytime naps over 30 min")
    ]
}

// MARK: - Sleep Habit Options
struct SleepHabit: Identifiable {
    let id: String
    let title: String
    let emoji: String
    let description: String

    static let options: [SleepHabit] = [
        SleepHabit(id: "terrible", title: "Terrible", emoji: "hand.thumbsdown.fill", description: "I barely sleep and feel exhausted"),
        SleepHabit(id: "poor", title: "Needs Work", emoji: "exclamationmark.triangle.fill", description: "Inconsistent schedule, often tired"),
        SleepHabit(id: "okay", title: "Okay", emoji: "equal.circle.fill", description: "Sometimes good, sometimes bad"),
        SleepHabit(id: "good", title: "Pretty Good", emoji: "checkmark.circle.fill", description: "Mostly consistent, want to improve"),
        SleepHabit(id: "great", title: "Great", emoji: "star.fill", description: "Just want to maintain my streak")
    ]
}

// MARK: - Default Routine Templates
struct RoutineTemplate {
    let title: String
    let icon: String
    let duration: Int
    let category: String

    static let defaults: [RoutineTemplate] = [
        RoutineTemplate(title: String(localized: "Put away screens"), icon: "iphone.slash", duration: 5, category: "wind-down"),
        RoutineTemplate(title: String(localized: "Dim the lights"), icon: "lightbulb.min", duration: 2, category: "environment"),
        RoutineTemplate(title: String(localized: "Journal or read"), icon: "book.fill", duration: 15, category: "wind-down"),
        RoutineTemplate(title: String(localized: "Stretching or yoga"), icon: "figure.yoga", duration: 10, category: "body"),
        RoutineTemplate(title: String(localized: "Deep breathing"), icon: "wind", duration: 5, category: "relaxation"),
        RoutineTemplate(title: String(localized: "Brush teeth & skincare"), icon: "drop.fill", duration: 10, category: "hygiene"),
        RoutineTemplate(title: String(localized: "Set alarm & charge phone"), icon: "alarm.fill", duration: 2, category: "prep"),
        RoutineTemplate(title: String(localized: "Gratitude reflection"), icon: "heart.fill", duration: 5, category: "mindset")
    ]
}

// MARK: - Energy Level
enum EnergyLevel: Int, CaseIterable {
    case exhausted = 1
    case tired = 2
    case okay = 3
    case energized = 4
    case supercharged = 5

    var emoji: String {
        switch self {
        case .exhausted: return "battery.0percent"
        case .tired: return "battery.25percent"
        case .okay: return "battery.50percent"
        case .energized: return "battery.75percent"
        case .supercharged: return "bolt.fill"
        }
    }

    var label: String {
        switch self {
        case .exhausted: return String(localized: "Exhausted")
        case .tired: return String(localized: "Tired")
        case .okay: return String(localized: "Okay")
        case .energized: return String(localized: "Energized")
        case .supercharged: return String(localized: "Supercharged")
        }
    }

    var color: Color {
        switch self {
        case .exhausted: return .red
        case .tired: return .orange
        case .okay: return .yellow
        case .energized: return Color(hex: "00E676")
        case .supercharged: return Color(hex: "6C5CE7")
        }
    }
}
