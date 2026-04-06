import SwiftUI
import SwiftData
import Charts

struct ProgressChartsView: View {
    @Query(sort: \SleepLogEntry.date) private var entries: [SleepLogEntry]
    @State private var selectedRange: ChartRange = .week

    enum ChartRange: String, CaseIterable {
        case week = "7D"
        case twoWeeks = "14D"
        case month = "30D"

        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }

    private var filteredEntries: [SleepLogEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedRange.days, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoff }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: SLTheme.Spacing.lg) {
                    // Range picker
                    Picker("Range", selection: $selectedRange) {
                        ForEach(ChartRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(SLTheme.Colors.primary)

                    // Sleep Consistency Chart
                    SLCard {
                        VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                            SLSectionHeader("Bedtime Consistency", subtitle: "Actual vs. target bedtime")

                            if filteredEntries.isEmpty {
                                emptyChartPlaceholder
                            } else {
                                Chart(filteredEntries) { entry in
                                    // Target line
                                    RuleMark(
                                        y: .value("Target", bedtimeMinutes(entry.targetBedtime))
                                    )
                                    .foregroundStyle(SLTheme.Colors.primary.opacity(0.3))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))

                                    // Actual bedtime
                                    LineMark(
                                        x: .value("Date", entry.date, unit: .day),
                                        y: .value("Bedtime", bedtimeMinutes(entry.actualBedtime))
                                    )
                                    .foregroundStyle(
                                        entry.hitTarget ? SLTheme.Colors.success : SLTheme.Colors.warning
                                    )
                                    .symbol {
                                        Circle()
                                            .fill(entry.hitTarget ? SLTheme.Colors.success : SLTheme.Colors.warning)
                                            .frame(width: 8, height: 8)
                                    }
                                    .interpolationMethod(.catmullRom)
                                }
                                .chartYScale(domain: .automatic(includesZero: false))
                                .chartYAxis {
                                    AxisMarks(values: .automatic) { value in
                                        AxisGridLine()
                                            .foregroundStyle(Color.white.opacity(0.05))
                                        AxisValueLabel {
                                            if let minutes = value.as(Double.self) {
                                                Text(minutesToTime(minutes))
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(SLTheme.Colors.textTertiary)
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day)) { value in
                                        AxisGridLine()
                                            .foregroundStyle(Color.white.opacity(0.05))
                                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                            .foregroundStyle(SLTheme.Colors.textTertiary)
                                    }
                                }
                                .frame(height: 200)
                            }
                        }
                    }

                    // Energy Trends Chart
                    SLCard {
                        VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                            SLSectionHeader("Energy Trends", subtitle: "Morning energy ratings")

                            if filteredEntries.isEmpty {
                                emptyChartPlaceholder
                            } else {
                                Chart(filteredEntries) { entry in
                                    BarMark(
                                        x: .value("Date", entry.date, unit: .day),
                                        y: .value("Energy", entry.morningEnergyRating)
                                    )
                                    .foregroundStyle(
                                        energyColor(for: entry.morningEnergyRating).gradient
                                    )
                                    .cornerRadius(4)
                                }
                                .chartYScale(domain: 0...5)
                                .chartYAxis {
                                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                                        AxisGridLine()
                                            .foregroundStyle(Color.white.opacity(0.05))
                                        AxisValueLabel {
                                            if let val = value.as(Int.self),
                                               let level = EnergyLevel(rawValue: val) {
                                                Text(level.emoji)
                                                    .font(.system(size: 12))
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day)) { _ in
                                        AxisGridLine()
                                            .foregroundStyle(Color.white.opacity(0.05))
                                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                            .foregroundStyle(SLTheme.Colors.textTertiary)
                                    }
                                }
                                .frame(height: 180)
                            }
                        }
                    }

                    // Sleep Duration Chart
                    SLCard {
                        VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                            SLSectionHeader("Sleep Duration", subtitle: "Hours of sleep per night")

                            if filteredEntries.isEmpty {
                                emptyChartPlaceholder
                            } else {
                                Chart(filteredEntries) { entry in
                                    AreaMark(
                                        x: .value("Date", entry.date, unit: .day),
                                        y: .value("Hours", Double(entry.sleepDurationMinutes) / 60)
                                    )
                                    .foregroundStyle(SLTheme.Colors.sleepBlue.opacity(0.2).gradient)
                                    .interpolationMethod(.catmullRom)

                                    LineMark(
                                        x: .value("Date", entry.date, unit: .day),
                                        y: .value("Hours", Double(entry.sleepDurationMinutes) / 60)
                                    )
                                    .foregroundStyle(SLTheme.Colors.sleepBlue)
                                    .interpolationMethod(.catmullRom)

                                    // 8-hour reference line
                                    RuleMark(y: .value("Ideal", 8))
                                        .foregroundStyle(SLTheme.Colors.success.opacity(0.3))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                }
                                .chartYScale(domain: 0...12)
                                .chartYAxis {
                                    AxisMarks(values: [0, 2, 4, 6, 8, 10, 12]) { value in
                                        AxisGridLine()
                                            .foregroundStyle(Color.white.opacity(0.05))
                                        AxisValueLabel {
                                            if let hours = value.as(Int.self) {
                                                Text("\(hours)h")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(SLTheme.Colors.textTertiary)
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day)) { _ in
                                        AxisGridLine()
                                            .foregroundStyle(Color.white.opacity(0.05))
                                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                            .foregroundStyle(SLTheme.Colors.textTertiary)
                                    }
                                }
                                .frame(height: 180)
                            }
                        }
                    }

                    // Averages
                    if !filteredEntries.isEmpty {
                        averagesCard
                    }
                }
                .padding(.horizontal, SLTheme.Spacing.md)
                .padding(.bottom, SLTheme.Spacing.huge)
            }
            .background(SLTheme.Colors.backgroundPrimary)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SLTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Averages Card
    private var averagesCard: some View {
        let avgDuration = filteredEntries.isEmpty ? 0 :
            filteredEntries.reduce(0) { $0 + $1.sleepDurationMinutes } / filteredEntries.count
        let avgEnergy = filteredEntries.isEmpty ? 0.0 :
            Double(filteredEntries.reduce(0) { $0 + $1.morningEnergyRating }) / Double(filteredEntries.count)
        let hitRate = filteredEntries.isEmpty ? 0.0 :
            Double(filteredEntries.filter(\.hitTarget).count) / Double(filteredEntries.count) * 100

        return SLCard {
            VStack(spacing: SLTheme.Spacing.sm) {
                Text("Period Averages")
                    .font(SLTheme.Typography.headline)
                    .foregroundStyle(.white)

                HStack(spacing: SLTheme.Spacing.sm) {
                    SLStatPill(
                        icon: "clock.fill",
                        value: "\(avgDuration / 60)h \(avgDuration % 60)m",
                        label: "Avg Sleep",
                        color: SLTheme.Colors.sleepBlue
                    )
                    SLStatPill(
                        icon: "bolt.fill",
                        value: String(format: "%.1f", avgEnergy),
                        label: "Avg Energy",
                        color: SLTheme.Colors.energyGreen
                    )
                    SLStatPill(
                        icon: "target",
                        value: "\(Int(hitRate))%",
                        label: "Hit Rate",
                        color: SLTheme.Colors.success
                    )
                }
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: SLTheme.Spacing.sm) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36))
                .foregroundStyle(SLTheme.Colors.textTertiary)
            Text("No data yet. Start logging your sleep!")
                .font(SLTheme.Typography.subheadline)
                .foregroundStyle(SLTheme.Colors.textTertiary)
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers
    private func bedtimeMinutes(_ date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        var minutes = Double(comps.hour ?? 0) * 60 + Double(comps.minute ?? 0)
        // Normalize: hours before noon count as next day (e.g., 1 AM = 25*60)
        if minutes < 720 { minutes += 1440 }
        return minutes
    }

    private func minutesToTime(_ minutes: Double) -> String {
        var m = Int(minutes)
        if m >= 1440 { m -= 1440 }
        let h = m / 60
        let min = m % 60
        let period = h >= 12 ? "PM" : "AM"
        let displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h)
        return "\(displayHour):\(String(format: "%02d", min)) \(period)"
    }

    private func energyColor(for rating: Int) -> Color {
        switch rating {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return SLTheme.Colors.energyGreen
        case 5: return SLTheme.Colors.primary
        default: return .gray
        }
    }
}
