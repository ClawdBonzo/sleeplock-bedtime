import Foundation
import UserNotifications

final class NotificationService: Sendable {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// - Parameter enforceBedtime: when `true` (SleepLock Pro), schedules the
    ///   at-bedtime and past-bedtime "Smart bedtime enforcement" nudges in
    ///   addition to the basic pre-bedtime reminder. Free users get only the
    ///   single pre-bedtime reminder.
    func scheduleBedtimeReminder(bedtime: Date, minutesBefore: Int, userName: String, enforceBedtime: Bool) {
        let center = UNUserNotificationCenter.current()

        // Remove old bedtime reminders
        center.removePendingNotificationRequests(withIdentifiers: [
            "bedtime-reminder",
            "bedtime-now",
            "bedtime-past"
        ])

        let calendar = Calendar.current
        let bedtimeComponents = calendar.dateComponents([.hour, .minute], from: bedtime)

        // Reminder before bedtime
        if minutesBefore > 0 {
            let reminderTime = calendar.date(byAdding: .minute, value: -minutesBefore, to: bedtime)!
            let reminderComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)

            let content = UNMutableNotificationContent()
            content.title = String(localized: "Bedtime in \(minutesBefore) min")
            content.body = String(localized: "Hey \(userName), time to start your sleep routine! Your energized self will thank you tomorrow.")
            content.sound = .default
            content.categoryIdentifier = "BEDTIME_REMINDER"

            let trigger = UNCalendarNotificationTrigger(dateMatching: reminderComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "bedtime-reminder", content: content, trigger: trigger)
            center.add(request)
        }

        // Smart bedtime enforcement (Pro only): at-bedtime + past-bedtime nudges.
        guard enforceBedtime else { return }

        // At bedtime
        let bedtimeContent = UNMutableNotificationContent()
        bedtimeContent.title = String(localized: "Bedtime Now!")
        bedtimeContent.body = String(localized: "Lights out, \(userName)! Keep your streak alive by getting to bed now.")
        bedtimeContent.sound = .default
        bedtimeContent.categoryIdentifier = "BEDTIME_NOW"

        let bedtimeTrigger = UNCalendarNotificationTrigger(dateMatching: bedtimeComponents, repeats: true)
        let bedtimeRequest = UNNotificationRequest(identifier: "bedtime-now", content: bedtimeContent, trigger: bedtimeTrigger)
        center.add(bedtimeRequest)

        // 15 min past bedtime (gentle nudge)
        let pastTime = calendar.date(byAdding: .minute, value: 15, to: bedtime)!
        let pastComponents = calendar.dateComponents([.hour, .minute], from: pastTime)

        let pastContent = UNMutableNotificationContent()
        pastContent.title = String(localized: "Still up?")
        pastContent.body = String(localized: "It's 15 minutes past your bedtime. Every minute counts for your streak and energy score!")
        pastContent.sound = .default

        let pastTrigger = UNCalendarNotificationTrigger(dateMatching: pastComponents, repeats: true)
        let pastRequest = UNNotificationRequest(identifier: "bedtime-past", content: pastContent, trigger: pastTrigger)
        center.add(pastRequest)
    }

    func scheduleMorningLog(wakeTime: Date, userName: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["morning-log"])

        let calendar = Calendar.current
        let logTime = calendar.date(byAdding: .minute, value: 15, to: wakeTime)!
        let components = calendar.dateComponents([.hour, .minute], from: logTime)

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Good Morning!")
        content.body = String(localized: "How did you sleep, \(userName)? Log your bedtime and energy level to keep your streak going!")
        content.sound = .default
        content.categoryIdentifier = "MORNING_LOG"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning-log", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
