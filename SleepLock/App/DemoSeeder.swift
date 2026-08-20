import Foundation
import SwiftData

/// One-shot demo data seeder for App Store screenshots.
///
/// Launch the app with `-SeedDemoData YES` to wipe existing data and
/// populate a realistic 14-day success story: 14-night streak, Sleep
/// Master level, strong energy scores, earned badges.
enum DemoSeeder {

    static func seedIfRequested(container: ModelContainer) {
        guard CommandLine.arguments.contains("-SeedDemoData") else { return }
        let context = ModelContext(container)
        wipe(context: context)
        seed(context: context)
        try? context.save()
    }

    // MARK: - Wipe

    private static func wipe(context: ModelContext) {
        try? context.delete(model: SleepLogEntry.self)
        try? context.delete(model: UserProfile.self)
        try? context.delete(model: RoutineStep.self)
        try? context.delete(model: GamificationProfile.self)
        try? context.delete(model: Badge.self)
        try? context.delete(model: Quest.self)
    }

    // MARK: - Seed

    private static func seed(context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        // Target bedtime: 10:30 PM, wake: 7:00 AM
        let targetBedtime = cal.date(from: DateComponents(hour: 22, minute: 30)) ?? now
        let targetWake = cal.date(from: DateComponents(hour: 7, minute: 0)) ?? now

        // UserProfile
        let profile = UserProfile(
            displayName: "Rob",
            targetBedtime: targetBedtime,
            targetWakeTime: targetWake,
            sleepBlockers: ["screens", "caffeine", "stress"],
            currentSleepHabit: "good",
            onboardingCompleted: true,
            createdAt: cal.date(byAdding: .day, value: -30, to: now) ?? now,
            notificationsEnabled: true,
            reminderMinutesBefore: 30
        )
        context.insert(profile)

        // 14 consecutive nights, all hit target, strong energy
        // Energies create an upward trend: start at 3, climb to 5
        let energies: [Int] = [3, 4, 3, 4, 4, 4, 5, 4, 5, 5, 4, 5, 5, 5]
        for daysAgo in 0..<14 {
            let dayDate = cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now

            // Bedtime within ±8 minutes of target (all "hit target")
            let bedtimeJitter = Int.random(in: -8...8)
            let wakeJitter = Int.random(in: -10...10)

            let actualBedtime = cal.date(
                bySettingHour: 22, minute: 30 + bedtimeJitter, second: 0,
                of: cal.date(byAdding: .day, value: -1, to: dayDate) ?? dayDate
            ) ?? dayDate
            let actualWake = cal.date(
                bySettingHour: 7, minute: wakeJitter, second: 0, of: dayDate
            ) ?? dayDate

            let entry = SleepLogEntry(
                date: dayDate,
                actualBedtime: actualBedtime,
                actualWakeTime: actualWake,
                targetBedtime: targetBedtime,
                morningEnergyRating: energies[13 - daysAgo],
                notes: "",
                hitTarget: true
            )
            context.insert(entry)
        }

        // Gamification — Sleep Master (level 4) with partial progress
        // XP thresholds: NightOwl 0, Sleepy 100, Restful 300, Master 600, Champion 1000
        // Put user at Sleep Master with 220/400 XP toward Champion.
        let gp = GamificationProfile(userId: UUID())
        gp.totalXP = 820
        gp.currentLevel = .sleepMaster
        gp.xpInCurrentLevel = 220  // toward Sleep Champion (1000 - 600 = 400 needed)
        gp.levelUpCount = 3
        gp.createdAt = cal.date(byAdding: .day, value: -30, to: now) ?? now
        gp.lastXPGainDate = now
        context.insert(gp)

        // Earned badges — the impressive ones
        let earnedBadgeTypes: [BadgeType] = [
            .firstBedtime,
            .week1Streak,
            .week2Streak,
            .perfectWeek,
            .level3,
            .energyChampion
        ]
        for (index, type) in earnedBadgeTypes.enumerated() {
            let badge = Badge(userId: gp.userId, type: type)
            badge.isUnlocked = true
            badge.unlockedAt = cal.date(byAdding: .day, value: -(14 - index * 2), to: now)
            context.insert(badge)
        }

        // Routine steps from defaults
        for (index, template) in RoutineTemplate.defaults.enumerated() {
            let step = RoutineStep(
                title: template.title,
                icon: template.icon,
                durationMinutes: template.duration,
                sortOrder: index,
                isEnabled: index < 6,
                category: template.category
            )
            context.insert(step)
        }
    }
}
