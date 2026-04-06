import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Timeline Entry
struct SleepLockEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
    let bedtime: String
    let energyScore: Int
    let hitTargetToday: Bool
}

// MARK: - Timeline Provider
struct SleepLockProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepLockEntry {
        SleepLockEntry(
            date: Date(),
            streakCount: 7,
            bedtime: "10:30 PM",
            energyScore: 78,
            hitTargetToday: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepLockEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepLockEntry>) -> Void) {
        let entry = SleepLockEntry(
            date: Date(),
            streakCount: 0,
            bedtime: "10:30 PM",
            energyScore: 0,
            hitTargetToday: false
        )

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Small Widget View
struct SleepLockSmallView: View {
    let entry: SleepLockEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 14))
                Text("\(entry.streakCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("nights")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            HStack {
                Image(systemName: "moon.fill")
                    .foregroundStyle(Color(hex: "A29BFE"))
                    .font(.system(size: 12))
                Text(entry.bedtime)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color(hex: "00E676"))
                    .font(.system(size: 12))
                Text("\(entry.energyScore)/100")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(hex: "0A0A1A")
        }
    }
}

// MARK: - Medium Widget View
struct SleepLockMediumView: View {
    let entry: SleepLockEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Streak
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 24))

                Text("\(entry.streakCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("night streak")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 8)

            // Right: Tonight
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(Color(hex: "A29BFE"))
                    Text("Tonight")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .font(.system(size: 12, design: .rounded))

                Text(entry.bedtime)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color(hex: "00E676"))
                    Text("Energy: \(entry.energyScore)/100")
                        .foregroundStyle(.white.opacity(0.7))
                }
                .font(.system(size: 12, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(hex: "0A0A1A")
        }
    }
}

// MARK: - Widget Configuration
struct SleepLockWidget: Widget {
    let kind: String = "SleepLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepLockProvider()) { entry in
            if #available(iOS 18.0, *) {
                Group {
                    switch WidgetFamily.systemSmall {
                    default:
                        SleepLockSmallView(entry: entry)
                    }
                }
            }
        }
        .configurationDisplayName("SleepLock")
        .description("Track your sleep streak and bedtime at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle
@main
struct SleepLockWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepLockWidget()
    }
}

// Color extension for widget
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
