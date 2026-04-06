import Foundation

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
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    var monthDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    var fullDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
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
}

extension Calendar {
    func datesInRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start.startOfDay
        let endDay = end.startOfDay
        while current <= endDay {
            dates.append(current)
            current = self.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
}
