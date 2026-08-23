import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @State private var streakService = SleepStreakService()
    @State private var gamificationService: GamificationService?
    @State private var showOnboarding: Bool?
    private var hasCompletedOnboarding: Bool {
        profiles.first?.onboardingCompleted ?? false
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
                } else {
                    // No launch paywall: the upgrade ask happens after the first
                    // logged night (DashboardView), once there's value to pay for.
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
