import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @State private var streakService = SleepStreakService()
    @State private var gamificationService: GamificationService?
    @State private var showOnboarding: Bool?
    // Tracks if user tapped "Maybe Later" this session — resets on next launch
    @State private var hasTemporarilyDismissedPaywall: Bool = {
        #if DEBUG
        return CommandLine.arguments.contains("-SkipLaunchPaywall")
        #else
        return false
        #endif
    }()

    private var hasCompletedOnboarding: Bool {
        profiles.first?.onboardingCompleted ?? false
    }

    private var isPremium: Bool {
        PurchaseService.shared.isPremium
    }

    var body: some View {
        Group {
            if let showOnboarding, let gamificationService {
                if showOnboarding {
                    OnboardingContainerView {
                        withAnimation {
                            self.showOnboarding = false
                        }
                    }
                    .environment(gamificationService)
                } else if !isPremium && !hasTemporarilyDismissedPaywall
                            && !PurchaseService.shared.hasSeenLaunchPaywallThisSession {
                    // Hard paywall gate — shown once per launch until subscribed.
                    // (The onboarding flow shows its own copy; hasSeenLaunchPaywall
                    // ThisSession prevents a back-to-back second paywall.)
                    PaywallView(
                        userName: profiles.first?.displayName ?? "",
                        onContinue: {
                            withAnimation { hasTemporarilyDismissedPaywall = true }
                        },
                        allowDismiss: false
                    )
                } else {
                    MainTabView(streakService: streakService)
                        .environment(gamificationService)
                }
            } else {
                // Loading state
                ZStack {
                    SLTheme.Colors.backgroundPrimary.ignoresSafeArea()
                    ProgressView()
                        .tint(SLTheme.Colors.primary)
                }
            }
        }
        .onAppear {
            if gamificationService == nil {
                gamificationService = GamificationService(modelContext: modelContext)
            }
            showOnboarding = !hasCompletedOnboarding
            streakService.configure(with: modelContext)
            rearmReengagement()
        }
        .onChange(of: profiles.count) {
            showOnboarding = !hasCompletedOnboarding
            streakService.configure(with: modelContext)
        }
    }

    /// Push the lapsed-user reminder ~2 days out on every launch. Because it's
    /// removed and re-added here, it only ever fires if the user does NOT return
    /// within the window.
    private func rearmReengagement() {
        guard let profile = profiles.first, profile.notificationsEnabled, profile.onboardingCompleted else { return }
        NotificationService.shared.scheduleReengagementReminder(
            userName: profile.displayName,
            currentStreak: streakService.currentStreak
        )
    }
}
