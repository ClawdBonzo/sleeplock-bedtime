import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @State private var streakService = SleepStreakService()
    @State private var showOnboarding: Bool?

    private var hasCompletedOnboarding: Bool {
        profiles.first?.onboardingCompleted ?? false
    }

    var body: some View {
        Group {
            if let showOnboarding {
                if showOnboarding {
                    OnboardingContainerView {
                        withAnimation {
                            self.showOnboarding = false
                        }
                    }
                } else {
                    MainTabView(streakService: streakService)
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
            showOnboarding = !hasCompletedOnboarding
            streakService.configure(with: modelContext)
        }
        .onChange(of: profiles.count) {
            showOnboarding = !hasCompletedOnboarding
            streakService.configure(with: modelContext)
        }
    }
}
