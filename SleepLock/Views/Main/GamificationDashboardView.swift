import SwiftUI
import SwiftData

struct GamificationDashboardView: View {
    @Environment(GamificationService.self) private var gamificationService

    var body: some View {
        NavigationStack {
            ZStack {
                SLTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: SLTheme.Spacing.lg) {
                        // Level Card
                        if let profile = gamificationService.gamificationProfile {
                            LevelProgressCard(profile: profile)
                        }

                        // Quick Stats
                        quickStatsRow(service: gamificationService)

                        // Daily Quests Section
                        if !gamificationService.dailyQuests.isEmpty {
                            questsSection(title: "Today's Quests", quests: gamificationService.dailyQuests)
                        }

                        // Weekly Quests Section
                        if !gamificationService.weeklyQuests.isEmpty {
                            questsSection(title: "Weekly Quests", quests: gamificationService.weeklyQuests)
                        }

                        // Badges Section
                        badgesSection(service: gamificationService)
                    }
                    .padding(.horizontal, SLTheme.Spacing.md)
                    .padding(.vertical, SLTheme.Spacing.lg)
                }
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if gamificationService.showLevelUpAnimation {
                    LevelUpAnimationView(level: gamificationService.lastLevelUpLevel ?? .nightOwl)
                }
            }
            .onAppear {
                // Re-sync so day rollovers and logs from other tabs show up.
                gamificationService.refresh()
            }
        }
    }

    // MARK: - Quick Stats

    private func quickStatsRow(service: GamificationService) -> some View {
        HStack(spacing: SLTheme.Spacing.md) {
            StatCard(
                sfSymbol: "sparkles",
                symbolColor: SLTheme.Colors.accent,
                label: "Total XP",
                value: "\(service.gamificationProfile?.totalXP ?? 0)"
            )

            StatCard(
                sfSymbol: "scope",
                symbolColor: SLTheme.Colors.primary,
                label: "Quests",
                value: "\(service.gamificationProfile?.completedQuestCount ?? service.completedQuestCount)"
            )

            StatCard(
                sfSymbol: "trophy.fill",
                symbolColor: SLTheme.Colors.streakGold,
                label: "Badges",
                value: "\(service.unlockedBadges.count)"
            )
        }
    }

    // MARK: - Quests Section

    private func questsSection(title: LocalizedStringKey, quests: [Quest]) -> some View {
        VStack(alignment: .leading, spacing: SLTheme.Spacing.md) {
            Label(title, systemImage: "checklist")
                .font(SLTheme.Typography.headline)
                .foregroundStyle(.white)

            VStack(spacing: SLTheme.Spacing.sm) {
                ForEach(quests, id: \.id) { quest in
                    QuestRowView(quest: quest)
                }
            }
        }
    }

    // MARK: - Badges Section

    private func badgesSection(service: GamificationService) -> some View {
        VStack(alignment: .leading, spacing: SLTheme.Spacing.md) {
            Label("Achievements", systemImage: "star.fill")
                .font(SLTheme.Typography.headline)
                .foregroundStyle(.white)

            BadgesGridView(gamificationService: service)
        }
    }
}

// MARK: - Level Progress Card

struct LevelProgressCard: View {
    let profile: GamificationProfile

    var body: some View {
        VStack(spacing: SLTheme.Spacing.md) {
            HStack(alignment: .top, spacing: SLTheme.Spacing.md) {
                VStack(spacing: SLTheme.Spacing.xs) {
                    Image(systemName: profile.currentLevel.sfSymbol)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(SLTheme.Colors.primaryLight)
                        .frame(width: 56, height: 56)
                        .background(SLTheme.Colors.primary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    Text(profile.currentLevel.displayName)
                        .font(SLTheme.Typography.headline)
                        .foregroundStyle(.white)
                }
                .frame(width: 100)

                Spacer()

                VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                    Text("Level \(profile.currentLevel.rawValue)")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)

                    ProgressView(value: profile.progressToNextLevel)
                        .tint(SLTheme.Colors.primary)
                        .frame(height: 8)

                    HStack {
                        Text("\(profile.xpInCurrentLevel) XP")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(SLTheme.Colors.textSecondary)

                        Spacer()

                        Text("/ \(profile.xpToNextLevel)")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(SLTheme.Colors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(SLTheme.Spacing.md)
        .background(SLTheme.Colors.gradientPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: SLTheme.Radius.xl)
                .stroke(SLTheme.Colors.primary.opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - Quest Row

/// Quests progress automatically from real behavior (logging sleep, hitting
/// bedtime, completing the routine) — there is deliberately no tap-to-claim
/// button, so XP is always earned.
struct QuestRowView: View {
    let quest: Quest

    var body: some View {
        VStack(spacing: SLTheme.Spacing.xs) {
            HStack(alignment: .center, spacing: SLTheme.Spacing.md) {
                Image(systemName: quest.objective.sfSymbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SLTheme.Colors.primaryLight)
                    .frame(width: 40, height: 40)
                    .background(SLTheme.Colors.primary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: SLTheme.Spacing.xxxs) {
                    HStack {
                        Text(quest.objective.displayText)
                            .font(SLTheme.Typography.body)
                            .foregroundStyle(.white)

                        Spacer()

                        if quest.targetProgress > 1 && !quest.isCompleted {
                            Text("\(quest.progress)/\(quest.targetProgress)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(SLTheme.Colors.textSecondary)
                        }

                        Text("+\(quest.objective.xpReward) XP")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(SLTheme.Colors.energyGreen)
                    }

                    ProgressView(value: quest.progress_percentage)
                        .tint(quest.isCompleted ? SLTheme.Colors.energyGreen : SLTheme.Colors.primary)
                        .frame(height: 4)
                }

                Image(systemName: quest.isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.system(size: 24))
                    .foregroundStyle(quest.isCompleted ? SLTheme.Colors.energyGreen : SLTheme.Colors.textTertiary)
                    .accessibilityLabel(quest.isCompleted ? "Completed" : "In progress")
            }
            .padding(SLTheme.Spacing.md)
            .background(quest.isCompleted ? SLTheme.Colors.energyGreen.opacity(0.08) : SLTheme.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
        }
    }
}

// MARK: - Badges Grid

struct BadgesGridView: View {
    let gamificationService: GamificationService

    let columns = [
        GridItem(.flexible(), spacing: SLTheme.Spacing.md),
        GridItem(.flexible(), spacing: SLTheme.Spacing.md),
        GridItem(.flexible(), spacing: SLTheme.Spacing.md)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: SLTheme.Spacing.md) {
            ForEach(gamificationService.badges, id: \.id) { badge in
                BadgeCardView(badge: badge)
            }
        }
    }
}

struct BadgeCardView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: SLTheme.Spacing.xs) {
            Image(systemName: badge.type.sfSymbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(badge.isUnlocked ? SLTheme.Colors.streakGold : SLTheme.Colors.textTertiary)
                .frame(width: 44, height: 44)
                .background(badge.isUnlocked ? SLTheme.Colors.streakGold.opacity(0.15) : SLTheme.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(badge.type.displayName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(badge.isUnlocked ? .white : SLTheme.Colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(SLTheme.Spacing.sm)
        .background(badge.isUnlocked ? SLTheme.Colors.primary.opacity(0.12) : SLTheme.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: SLTheme.Radius.md)
                .stroke(badge.isUnlocked ? SLTheme.Colors.primary.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let sfSymbol: String
    let symbolColor: Color
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(spacing: SLTheme.Spacing.xs) {
            Image(systemName: sfSymbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(symbolColor)

            Text(value)
                .font(SLTheme.Typography.headline)
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(SLTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(SLTheme.Spacing.md)
        .background(SLTheme.Colors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
    }
}

// MARK: - Level Up Animation

struct LevelUpAnimationView: View {
    let level: SleepLevel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: SLTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(SLTheme.Colors.primary.opacity(0.2))
                        .blur(radius: 30)
                        .scaleEffect(scale * 1.5)

                    Image(systemName: level.sfSymbol)
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(SLTheme.Colors.primaryLight)
                        .scaleEffect(scale)
                        .rotation3DEffect(
                            .degrees(rotation),
                            axis: (x: 1, y: 1, z: 0)
                        )
                }

                VStack(spacing: SLTheme.Spacing.sm) {
                    Text("Level Up!")
                        .font(SLTheme.Typography.largeTitle)
                        .foregroundStyle(.white)

                    Text(level.displayName)
                        .font(SLTheme.Typography.headline)
                        .foregroundStyle(SLTheme.Colors.primary)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            if reduceMotion {
                scale = 1.0
                withAnimation(.easeIn(duration: 0.3)) { opacity = 1.0 }
                return
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            withAnimation(.linear(duration: 1.0).delay(0.3)) {
                rotation = 360
            }
        }
    }
}
