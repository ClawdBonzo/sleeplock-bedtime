import Foundation

/// Bridges the main app and the widget extension via a shared App Group
/// container. The app writes the latest sleep snapshot; the widget reads it.
/// No data leaves the device — the App Group is local storage only.
enum SharedSnapshot {
    static let appGroup = "group.com.clawdbonzo.SleepLock"
    private static let key = "widgetSnapshot"

    struct WidgetData: Codable {
        var isPremium: Bool
        var streakCount: Int
        var bedtime: String
        var energyScore: Int
        var hitTargetToday: Bool

        static let placeholder = WidgetData(
            isPremium: true,
            streakCount: 7,
            bedtime: "10:30 PM",
            energyScore: 78,
            hitTargetToday: true
        )
    }

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func save(_ data: WidgetData) {
        guard let defaults, let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: key)
    }

    static func load() -> WidgetData? {
        guard let defaults,
              let raw = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: raw)
        else { return nil }
        return decoded
    }
}
