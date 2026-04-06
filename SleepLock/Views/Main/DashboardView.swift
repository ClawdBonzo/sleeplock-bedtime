import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \SleepLogEntry.date, order: .reverse) private var entries: [SleepLogEntry]

    @Bindable var streakService: SleepStreakService

    @State private var showLogger = false

    private var profile: UserProfile? { profiles.first }
    private var latestEntry: SleepLogEntry? { entries.first }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: SLTheme.Spacing.lg) {
                    // Greeting
                    greetingSection

                    // Streak Hero
                    streakHeroCard

                    // Tonight's Bedtime
                    bedtimeCard

                    // Energy Score
                    energyScoreCard

                    // Quick Stats
                    statsRow

                    // Quick Log CTA
                    if !streakService.todayLogged {
                        quickLogCard
                    }
                }
                .padding(.horizontal, SLTheme.Spacing.md)
                .padding(.bottom, SLTheme.Spacing.huge)
            }
            .background(SLTheme.Colors.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLogger) {
                DailyLoggerView()
                    .onDisappear { streakService.recalculate() }
            }
        }
    }

    // MARK: - Greeting
    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: SLTheme.Spacing.xxs) {
                Text(greetingText)
                    .font(SLTheme.Typography.title2)
                    .foregroundStyle(.white)

                Text(profile?.displayName ?? "Sleeper")
                    .font(SLTheme.Typography.largeTitle)
                    .foregroundStyle(SLTheme.Colors.primaryLight)
            }
            Spacer()
            Image(systemName: greetingIcon)
                .font(.system(size: 32))
                .foregroundStyle(SLTheme.Colors.moonGlow)
        }
        .padding(.top, SLTheme.Spacing.md)
    }

    // MARK: - Streak Hero
    private var streakHeroCard: some View {
        SLGlowCard(glowColor: SLTheme.Colors.streakGold) {
            VStack(spacing: SLTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(SLTheme.Colors.streakGold)
                    Text("Current Streak")
                        .font(SLTheme.Typography.headline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                    Spacer()
                    if streakService.currentStreak > 0 {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(SLTheme.Colors.streakGold)
                    }
                }

                Text("\(streakService.currentStreak)")
                    .font(SLTheme.Typography.streakNumber)
                    .foregroundStyle(SLTheme.Colors.streakGold)
                    .shadow(color: SLTheme.Colors.streakGold.opacity(0.3), radius: 10)

                Text(streakService.currentStreak == 1 ? "night" : "nights")
                    .font(SLTheme.Typography.subheadline)
                    .foregroundStyle(SLTheme.Colors.textSecondary)

                if streakService.longestStreak > streakService.currentStreak {
                    Text("Best: \(streakService.longestStreak) nights")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Bedtime Card
    private var bedtimeCard: some View {
        SLCard {
            HStack {
                VStack(alignment: .leading, spacing: SLTheme.Spacing.xs) {
                    Label("Tonight's Bedtime", systemImage: "moon.fill")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)

                    Text(profile?.targetBedtime.shortTime ?? "10:30 PM")
                        .font(SLTheme.Typography.title)
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: SLTheme.Spacing.xs) {
                    Label("Wake Up", systemImage: "sun.max.fill")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)

                    Text(profile?.targetWakeTime.shortTime ?? "7:00 AM")
                        .font(SLTheme.Typography.title)
                        .foregroundStyle(SLTheme.Colors.accent)
                }
            }
        }
    }

    // MARK: - Energy Score
    private var energyScoreCard: some View {
        SLGlowCard(glowColor: SLTheme.Colors.energyGreen) {
            HStack {
                VStack(alignment: .leading, spacing: SLTheme.Spacing.xs) {
                    Label("Energy Score", systemImage: "bolt.fill")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: SLTheme.Spacing.xxs) {
                        Text("\(Int(streakService.energyScore))")
                            .font(SLTheme.Typography.energyScore)
                            .foregroundStyle(SLTheme.Colors.energyGreen)

                        Text("/100")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(SLTheme.Colors.textTertiary)
                    }

                    Text("Based on last 7 days")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                }

                Spacer()

                SLProgressRing(
                    progress: streakService.energyScore / 100,
                    lineWidth: 10,
                    size: 80,
                    color: SLTheme.Colors.energyGreen
                )
                .overlay {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(SLTheme.Colors.energyGreen)
                }
            }
        }
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: SLTheme.Spacing.sm) {
            SLStatPill(
                icon: "chart.bar.fill",
                value: "\(Int(streakService.weeklyConsistency))%",
                label: "Consistency",
                color: SLTheme.Colors.sleepBlue
            )

            SLStatPill(
                icon: "calendar",
                value: "\(entries.count)",
                label: "Nights Logged",
                color: SLTheme.Colors.secondary
            )

            SLStatPill(
                icon: "trophy.fill",
                value: "\(streakService.longestStreak)",
                label: "Best Streak",
                color: SLTheme.Colors.streakGold
            )
        }
    }

    // MARK: - Quick Log
    private var quickLogCard: some View {
        Button { showLogger = true } label: {
            HStack(spacing: SLTheme.Spacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(SLTheme.Colors.primary)

                VStack(alignment: .leading, spacing: SLTheme.Spacing.xxxs) {
                    Text("Log Last Night's Sleep")
                        .font(SLTheme.Typography.headline)
                        .foregroundStyle(.white)

                    Text("Keep your streak alive!")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(SLTheme.Colors.textTertiary)
            }
            .padding(SLTheme.Spacing.md)
            .background(SLTheme.Colors.primary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: SLTheme.Radius.xl)
                    .stroke(SLTheme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "sun.max.fill"
        case 12..<17: return "sun.min.fill"
        case 17..<21: return "sunset.fill"
        default: return "moon.stars.fill"
        }
    }
}
