import Foundation

/// Clock math for a single night of sleep. Bed/wake times are compared on a
/// wrap-around "sleep clock" whose day starts at noon, so times after midnight
/// (1:45 AM) correctly sort *after* evening times (10:30 PM).
enum NightMath {
    /// Minutes past 12:00 noon on the sleep clock: 22:30 → 630, 01:45 → 825.
    static func sleepClockMinutes(_ date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let raw = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let noon = 12 * 60
        return raw >= noon ? raw - noon : raw + noon
    }

    /// Whether an actual bedtime hits the target, allowing `graceMinutes` of
    /// lateness. Going to bed early is always a hit — including a pre-midnight
    /// bedtime against a post-midnight target.
    static func hitsTarget(actualBedtime: Date, targetBedtime: Date, graceMinutes: Int = 15) -> Bool {
        sleepClockMinutes(actualBedtime) <= sleepClockMinutes(targetBedtime) + graceMinutes
    }

    /// Minutes from bedtime to wake time. Manual logs store both as time-of-day
    /// on the same reference day, so a negative interval means the wake time
    /// belongs to the next morning — wrap it by 24h instead of clamping to 0.
    static func durationMinutes(bedtime: Date, wakeTime: Date) -> Int {
        let interval = wakeTime.timeIntervalSince(bedtime)
        if interval > 0 { return Int(interval / 60) }
        let wrapped = interval + 24 * 60 * 60
        return wrapped > 0 ? Int(wrapped / 60) : 0
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var shortTime: String {
        Date.shortTimeFormatter.string(from: self)
    }

    var dayOfWeek: String {
        Date.dayOfWeekFormatter.string(from: self)
    }

    var monthDay: String {
        Date.monthDayFormatter.string(from: self)
    }

    var fullDate: String {
        Date.fullDateFormatter.string(from: self)
    }

    func daysFrom(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date.startOfDay, to: self.startOfDay).day ?? 0
    }

    static func bedtimeFrom(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    var hourMinuteComponents: (hour: Int, minute: Int) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: self)
        return (comps.hour ?? 0, comps.minute ?? 0)
    }

    // MARK: - Cached formatters

    private static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        // Locale-aware: 12-hour with AM/PM in en, 24-hour in de/sv/etc.
        f.setLocalizedDateFormatFromTemplate("jmm")
        return f
    }()

    private static let dayOfWeekFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f
    }()

    private static let monthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return f
    }()

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
}

extension Calendar {
    func datesInRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start.startOfDay
        let endDay = end.startOfDay
        while current <= endDay {
            dates.append(current)
            guard let next = self.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }
}
