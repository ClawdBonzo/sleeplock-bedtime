import SwiftUI
import SwiftData
import WidgetKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \SleepLogEntry.date, order: .reverse) private var entries: [SleepLogEntry]

    @Bindable var streakService: SleepStreakService

    @State private var showLogger = false
    @State private var gamificationService: GamificationService?
    @State private var deepLinkAnalytics = false

    private var profile: UserProfile? { profiles.first }
    private var latestEntry: SleepLogEntry? { entries.first }
    private var isPremium: Bool { PurchaseService.shared.isPremium }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: SLTheme.Spacing.lg) {
                        // Greeting
                        greetingSection

                        // Gamification Level (if available)
                        if let service = gamificationService, let profile = service.gamificationProfile {
                            gamificationCard(profile: profile)
                        }

                        // Streak Hero
                        streakHeroCard

                        // Tonight's Bedtime
                        bedtimeCard

                        // Energy Score
                        energyScoreCard

                        // Quick Stats
                        statsRow

                        // Sleep Analytics (Pro)
                        analyticsCard

                        // Quick Log CTA
                        if !streakService.todayLogged {
                            quickLogCard
                        }
                    }
                    .padding(.horizontal, SLTheme.Spacing.md)
                    .padding(.bottom, SLTheme.Spacing.huge)
                }
                .background(SLTheme.Colors.backgroundPrimary)

                // Level Up Overlay
                if let service = gamificationService, service.showLevelUpAnimation {
                    LevelUpAnimationView(level: service.lastLevelUpLevel ?? .nightOwl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLogger) {
                DailyLoggerView()
                    .onDisappear {
                        streakService.recalculate()
                        writeWidgetSnapshot()
                    }
            }
            .navigationDestination(isPresented: $deepLinkAnalytics) {
                ProgressChartsView()
                    .proGated(.analytics, isPremium: isPremium, userName: profile?.displayName ?? "")
            }
            .onAppear {
                if gamificationService == nil {
                    gamificationService = GamificationService(modelContext: modelContext)
                }
                writeWidgetSnapshot()
                #if DEBUG
                if CommandLine.arguments.contains("-ShowAnalytics") { deepLinkAnalytics = true }
                #endif
            }
        }
    }

    // MARK: - Gamification Card
    private func gamificationCard(profile: GamificationProfile) -> some View {
        SLCard {
            HStack(spacing: SLTheme.Spacing.md) {
                VStack(spacing: SLTheme.Spacing.xs) {
                    Image(systemName: profile.currentLevel.sfSymbol)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(SLTheme.Colors.primaryLight)
                        .frame(width: 48, height: 48)
                        .background(SLTheme.Colors.primary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text(profile.currentLevel.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 60)

                Spacer()

                VStack(alignment: .leading, spacing: SLTheme.Spacing.xs) {
                    Text("Level \(profile.currentLevel.rawValue)")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textSecondary)

                    ProgressView(value: profile.progressToNextLevel)
                        .tint(SLTheme.Colors.primary)
                        .frame(height: 6)

                    HStack {
                        Text("\(profile.xpInCurrentLevel)/\(profile.xpToNextLevel) XP")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(SLTheme.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
            Button {
                showLogger = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [SLTheme.Colors.primary, Color(hex: "8B5CF6")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: SLTheme.Colors.primary.opacity(0.4), radius: 8, y: 2)
            }
            .accessibilityLabel("Log last night's sleep")
        }
        .padding(.top, SLTheme.Spacing.md)
    }

    // MARK: - Streak Hero
    private var streakHeroCard: some View {
        SLGlowCard(glowColor: SLTheme.Colors.streakGold) {
            HStack(spacing: SLTheme.Spacing.md) {
                // Left: label
                HStack(spacing: SLTheme.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(SLTheme.Colors.streakGold)
                    Text("Current Streak")
                        .font(SLTheme.Typography.headline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                Spacer(minLength: 0)

                // Right: number + unit + best
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(streakService.currentStreak)")
                        .font(SLTheme.Typography.title)
                        .foregroundStyle(SLTheme.Colors.streakGold)
                        .shadow(color: SLTheme.Colors.streakGold.opacity(0.3), radius: 8)
                    Text(streakService.currentStreak == 1 ? "night" : "nights")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                if streakService.longestStreak > streakService.currentStreak {
                    Text("Best \(streakService.longestStreak)")
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

    // MARK: - Sleep Analytics (Pro)
    private var analyticsCard: some View {
        NavigationLink {
            ProgressChartsView()
                .proGated(.analytics, isPremium: isPremium, userName: profile?.displayName ?? "")
        } label: {
            HStack(spacing: SLTheme.Spacing.md) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 28))
                    .foregroundStyle(SLTheme.Colors.sleepBlue)
                    .frame(width: 44, height: 44)
                    .background(SLTheme.Colors.sleepBlue.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: SLTheme.Spacing.xxxs) {
                    Text("Sleep Analytics")
                        .font(SLTheme.Typography.headline)
                        .foregroundStyle(.white)

                    Text("Consistency, energy & duration trends")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: isPremium ? "chevron.right" : "lock.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isPremium ? SLTheme.Colors.textTertiary : SLTheme.Colors.streakGold)
            }
            .padding(SLTheme.Spacing.md)
            .background(SLTheme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: SLTheme.Radius.xl)
                    .stroke(SLTheme.Colors.sleepBlue.opacity(0.2), lineWidth: 1)
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

    // MARK: - Widget Snapshot
    private func writeWidgetSnapshot() {
        SharedSnapshot.save(.init(
            isPremium: isPremium,
            streakCount: streakService.currentStreak,
            bedtime: profile?.targetBedtime.shortTime ?? "10:30 PM",
            energyScore: Int(streakService.energyScore),
            hitTargetToday: streakService.todayLogged
        ))
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Helpers
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return String(localized: "Good Morning")
        case 12..<17: return String(localized: "Good Afternoon")
        case 17..<21: return String(localized: "Good Evening")
        default: return String(localized: "Good Night")
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
