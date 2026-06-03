import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Entry
struct SleepLockEntry: TimelineEntry {
    let date: Date
    let isPremium: Bool
    let streakCount: Int
    let bedtime: String
    let energyScore: Int
    let hitTargetToday: Bool

    init(date: Date, data: SharedSnapshot.WidgetData) {
        self.date = date
        self.isPremium = data.isPremium
        self.streakCount = data.streakCount
        self.bedtime = data.bedtime
        self.energyScore = data.energyScore
        self.hitTargetToday = data.hitTargetToday
    }
}

// MARK: - Timeline Provider
struct SleepLockProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepLockEntry {
        SleepLockEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepLockEntry) -> Void) {
        let data = SharedSnapshot.load() ?? .placeholder
        completion(SleepLockEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepLockEntry>) -> Void) {
        // Read the latest snapshot written by the app (App Group, on-device only).
        let data = SharedSnapshot.load() ?? SharedSnapshot.WidgetData(
            isPremium: false, streakCount: 0, bedtime: "10:30 PM",
            energyScore: 0, hitTargetToday: false
        )
        let entry = SleepLockEntry(date: Date(), data: data)

        // Battery-friendly cadence: refresh tightly around the two moments that
        // matter (the ~11 PM bedtime/streak-risk window and the ~7 AM morning-log
        // window), and lazily every 4 hours otherwise. Hourly all-day refresh
        // drained energy for a tile whose data only changes at those times.
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let refreshHours: Int = (hour == 22 || hour == 23 || hour == 6 || hour == 7) ? 1 : 4
        let nextUpdate = calendar.date(byAdding: .hour, value: refreshHours, to: now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Branded Static Tile
//
// NOTE: Live-data widgets require an App Group shared container. Until the
// App Group `group.com.clawdbonzo.SleepLock` is registered (one interactive
// Xcode/portal step), the widget renders this branded tile instead of reading
// live streak/bedtime data. Re-enable the App Group capability + restore
// SleepLockEntryView's family-aware data views to bring live data back.
struct SleepLockBrandedView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("BrandIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text("SleepLock")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Lock in your best sleep")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .containerBackground(for: .widget) { Color(hex: "0A1428") }
    }
}

// MARK: - Entry View
struct SleepLockEntryView: View {
    let entry: SleepLockEntry

    var body: some View {
        // Static branded tile until the App Group is registered (see note above).
        SleepLockBrandedView()
    }
}

// MARK: - Small Widget View
struct SleepLockSmallView: View {
    let entry: SleepLockEntry

    var body: some View {
        ZStack {
            Image("Widget-Small")
                .resizable()
                .aspectRatio(contentMode: .fill)

            // Overlay content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image("BrandIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    Spacer()
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 12))
                }

                Spacer()

                Text("\(entry.streakCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("night streak")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 4) {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(Color(hex: "A29BFE"))
                        .font(.system(size: 10))
                    Text(entry.bedtime)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(14)
        }
        .containerBackground(for: .widget) {
            Color(hex: "0A1428")
        }
    }
}

// MARK: - Medium Widget View
struct SleepLockMediumView: View {
    let entry: SleepLockEntry

    var body: some View {
        ZStack {
            Image("Widget-Medium")
                .resizable()
                .aspectRatio(contentMode: .fill)

            HStack(spacing: 16) {
                // Left: Brand + Streak
                VStack(spacing: 6) {
                    Image("BrandIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

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
                    .fill(.white.opacity(0.15))
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
        }
        .containerBackground(for: .widget) {
            Color(hex: "0A1428")
        }
    }
}

// MARK: - Widget Configuration
struct SleepLockWidget: Widget {
    let kind: String = "SleepLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepLockProvider()) { entry in
            SleepLockEntryView(entry: entry)
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

// Color extension for widget (standalone since widget is separate target)
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
