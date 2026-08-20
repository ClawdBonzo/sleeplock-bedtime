import SwiftUI
import SwiftData

struct StreakCalendarView: View {
    @Query(sort: \SleepLogEntry.date, order: .reverse) private var entries: [SleepLogEntry]
    @State private var selectedMonth = Date()

    private var calendar: Calendar { Calendar.current }

    /// Entries indexed by day-key so day cells resolve in O(1) instead of
    /// scanning the whole history per cell. Latest entry per day wins.
    private var entriesByDay: [String: SleepLogEntry] {
        var index: [String: SleepLogEntry] = [:]
        for entry in entries {
            let key = GamificationProfile.dayKey(for: entry.date)
            if index[key] == nil { index[key] = entry } // entries are date-desc
        }
        return index
    }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth) else { return [] }
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        return range.compactMap { day -> Date? in
            var dayComponents = components
            dayComponents.day = day
            return calendar.date(from: dayComponents)
        }
    }

    private var firstWeekdayOffset: Int {
        guard let firstDay = daysInMonth.first else { return 0 }
        return (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    }

    /// Locale-aware weekday headers, rotated to the calendar's first weekday.
    private var weekdayHeaders: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(first + $0) % 7] }
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        return formatter
    }()

    private var monthTitle: String {
        Self.monthTitleFormatter.string(from: selectedMonth)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: SLTheme.Spacing.lg) {
                    // Month navigator
                    HStack {
                        Button { changeMonth(by: -1) } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(SLTheme.Colors.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Previous month")

                        Spacer()

                        Text(monthTitle)
                            .font(SLTheme.Typography.title2)
                            .foregroundStyle(.white)

                        Spacer()

                        Button { changeMonth(by: 1) } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(isCurrentMonth ? SLTheme.Colors.textTertiary.opacity(0.4) : SLTheme.Colors.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(isCurrentMonth) // no browsing into empty future months
                        .accessibilityLabel("Next month")
                    }
                    .padding(.horizontal, SLTheme.Spacing.sm)

                    // Day headers
                    HStack {
                        ForEach(weekdayHeaders, id: \.self) { day in
                            Text(day)
                                .font(SLTheme.Typography.caption)
                                .foregroundStyle(SLTheme.Colors.textTertiary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Calendar grid — index computed once per render, not per cell
                    let dayIndex = entriesByDay
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: SLTheme.Spacing.xs) {
                        // Offset for first day
                        ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                            Color.clear.frame(height: 44)
                        }

                        ForEach(daysInMonth, id: \.self) { date in
                            CalendarDayCell(
                                date: date,
                                entry: dayIndex[GamificationProfile.dayKey(for: date)],
                                isToday: calendar.isDateInToday(date)
                            )
                        }
                    }

                    // Legend
                    SLCard {
                        VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                            Text("Legend")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(.white)

                            HStack(spacing: SLTheme.Spacing.lg) {
                                LegendItem(color: SLTheme.Colors.success, label: "Hit Target")
                                LegendItem(color: SLTheme.Colors.warning, label: "Missed")
                                LegendItem(color: SLTheme.Colors.backgroundTertiary, label: "No Log")
                            }
                        }
                    }

                    // Month stats
                    monthStatsCard
                }
                .padding(.horizontal, SLTheme.Spacing.md)
                .padding(.bottom, SLTheme.Spacing.huge)
            }
            .background(SLTheme.Colors.backgroundPrimary)
            .navigationTitle("Streak Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SLTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Month Stats
    private var monthStatsCard: some View {
        let monthEntries = entries.filter { entry in
            calendar.isDate(entry.date, equalTo: selectedMonth, toGranularity: .month)
        }
        let onTarget = monthEntries.filter(\.hitTarget).count
        let total = monthEntries.count

        return SLCard {
            VStack(spacing: SLTheme.Spacing.sm) {
                Text("Month Summary")
                    .font(SLTheme.Typography.headline)
                    .foregroundStyle(.white)

                HStack(spacing: SLTheme.Spacing.xl) {
                    SLStatPill(
                        icon: "checkmark.circle.fill",
                        value: "\(onTarget)",
                        label: "On Target",
                        color: SLTheme.Colors.success
                    )
                    SLStatPill(
                        icon: "xmark.circle.fill",
                        value: "\(total - onTarget)",
                        label: "Missed",
                        color: SLTheme.Colors.warning
                    )
                    SLStatPill(
                        icon: "percent",
                        value: total > 0 ? "\(Int(Double(onTarget) / Double(total) * 100))%" : "—",
                        label: "Hit Rate",
                        color: SLTheme.Colors.sleepBlue
                    )
                }
            }
        }
    }

    private func changeMonth(by value: Int) {
        withAnimation {
            selectedMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) ?? selectedMonth
        }
    }
}

// MARK: - Calendar Day Cell
private struct CalendarDayCell: View {
    let date: Date
    let entry: SleepLogEntry?
    let isToday: Bool

    var body: some View {
        let day = Calendar.current.component(.day, from: date)

        ZStack {
            if let entry {
                RoundedRectangle(cornerRadius: SLTheme.Radius.sm)
                    .fill(entry.hitTarget ? SLTheme.Colors.success.opacity(0.2) : SLTheme.Colors.warning.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: SLTheme.Radius.sm)
                            .stroke(entry.hitTarget ? SLTheme.Colors.success : SLTheme.Colors.warning, lineWidth: 1)
                    )
            } else if date <= Date() {
                RoundedRectangle(cornerRadius: SLTheme.Radius.sm)
                    .fill(SLTheme.Colors.backgroundTertiary.opacity(0.5))
            }

            VStack(spacing: 1) {
                Text("\(day)")
                    .font(SLTheme.Typography.captionBold)
                    .foregroundStyle(isToday ? SLTheme.Colors.primary : .white)

                if let entry {
                    Text(entry.hitTarget ? "✓" : "✗")
                        .font(.system(size: 8))
                        .foregroundStyle(entry.hitTarget ? SLTheme.Colors.success : SLTheme.Colors.warning)
                }
            }
        }
        .frame(height: 44)
        .overlay(
            isToday ?
                RoundedRectangle(cornerRadius: SLTheme.Radius.sm)
                    .stroke(SLTheme.Colors.primary, lineWidth: 2)
                : nil
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// VoiceOver reads the hit/miss state that sighted users get from color.
    private var accessibilityText: String {
        var label = date.monthDay
        if isToday { label += ", " + String(localized: "today") }
        if let entry {
            label += ", " + (entry.hitTarget
                ? String(localized: "hit bedtime target")
                : String(localized: "missed bedtime target"))
        } else {
            label += ", " + String(localized: "not logged")
        }
        return label
    }
}

// MARK: - Legend Item
private struct LegendItem: View {
    let color: Color
    let label: LocalizedStringKey

    var body: some View {
        HStack(spacing: SLTheme.Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(SLTheme.Typography.caption)
                .foregroundStyle(SLTheme.Colors.textSecondary)
        }
    }
}
