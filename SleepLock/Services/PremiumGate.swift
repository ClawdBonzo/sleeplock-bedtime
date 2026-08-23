import SwiftUI

// MARK: - Legal URLs
//
// Apple Guideline 3.1.2 requires functional links to a Terms of Use (EULA)
// and Privacy Policy from any auto-renewable-subscription paywall.
//
// `terms` uses Apple's standard EULA, which Apple accepts when an app does not
// ship its own. `privacy` MUST point at a live privacy policy hosted by you —
// replace the placeholder before submission.
enum SLLegal {
    static let terms = URL(string: "https://gwlabs.app/terms")!
    static let privacy = URL(string: "https://gwlabs.app/privacy")!
    /// App Store product page (App ID 6761796877) — used for Share.
    static let appStore = URL(string: "https://apps.apple.com/app/id6761796877")!
    /// Deep link straight to the review composer — unlike `requestReview`
    /// this is never throttled, so it's the right target for an explicit
    /// "Rate SleepLock" button.
    static let writeReview = URL(string: "https://apps.apple.com/app/id6761796877?action=write-review")!
}

// MARK: - Pro Feature Definition

struct ProFeature {
    let icon: String
    let title: String
    let subtitle: String
    /// Bullet points shown on the locked screen — should mirror the paywall copy.
    let highlights: [String]

    static let analytics = ProFeature(
        icon: "chart.line.uptrend.xyaxis",
        title: String(localized: "Advanced Sleep Analytics"),
        subtitle: String(localized: "See the trends behind your sleep — bedtime consistency, energy, and duration over time."),
        highlights: [
            String(localized: "Bedtime consistency charts"),
            String(localized: "Energy & duration trends"),
            String(localized: "7 / 14 / 30-day windows")
        ]
    )

    static let gamification = ProFeature(
        icon: "star.fill",
        title: String(localized: "Full Gamification + XP"),
        subtitle: String(localized: "Level up your sleep with XP, quests, and achievement badges."),
        highlights: [
            String(localized: "Daily & weekly quests"),
            String(localized: "Sleep levels & XP"),
            String(localized: "Unlockable achievement badges")
        ]
    )

    static let streaks = ProFeature(
        icon: "flame.fill",
        title: String(localized: "Unlimited Streak Tracking"),
        subtitle: String(localized: "Your full streak history, month by month, with hit-rate stats."),
        highlights: [
            String(localized: "Full calendar history"),
            String(localized: "Monthly hit-rate stats"),
            String(localized: "Never lose your record")
        ]
    )
}

// MARK: - Locked Feature Screen

/// Full-screen "locked" state shown in place of a premium feature for free users.
/// Presents the paywall on tap; the parent re-evaluates `isPremium` once it dismisses.
struct ProLockedView: View {
    let feature: ProFeature
    var userName: String = ""

    @State private var showPaywall = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            SLTheme.Colors.backgroundPrimary.ignoresSafeArea()
            StarsBackground().ignoresSafeArea()

            VStack(spacing: SLTheme.Spacing.lg) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(SLTheme.Colors.primary.opacity(0.18))
                        .frame(width: 120, height: 120)
                        .blur(radius: 24)

                    Image(systemName: feature.icon)
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(SLTheme.Colors.primaryLight)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(SLTheme.Colors.streakGold, in: Circle())
                        .offset(x: 34, y: 34)
                }
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: SLTheme.Spacing.sm) {
                    Text(feature.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(feature.subtitle)
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SLTheme.Spacing.xl)
                }

                VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                    ForEach(feature.highlights, id: \.self) { item in
                        HStack(spacing: SLTheme.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SLTheme.Colors.energyGreen)
                            Text(item)
                                .font(SLTheme.Typography.body)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                    }
                }
                .padding(SLTheme.Spacing.lg)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, SLTheme.Spacing.xl)

                Spacer()

                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: SLTheme.Spacing.sm) {
                        Image(systemName: "crown.fill")
                        Text("Unlock SleepLock Pro")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [SLTheme.Colors.primary, Color(hex: "8B5CF6")],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    )
                    .shadow(color: SLTheme.Colors.primary.opacity(0.4), radius: 12, y: 4)
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .padding(.bottom, SLTheme.Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(
                userName: userName,
                onContinue: { showPaywall = false }
            )
        }
    }
}

// MARK: - Gate Modifier

extension View {
    /// Shows the wrapped content when the user has Pro, otherwise replaces it
    /// with a `ProLockedView` for the given feature.
    @ViewBuilder
    func proGated(_ feature: ProFeature, isPremium: Bool, userName: String = "") -> some View {
        if isPremium {
            self
        } else {
            ProLockedView(feature: feature, userName: userName)
        }
    }
}
