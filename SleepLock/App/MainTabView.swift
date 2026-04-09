import SwiftUI

struct MainTabView: View {
    @Bindable var streakService: SleepStreakService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(streakService: streakService)
                .tabItem { Label("Home", systemImage: "moon.stars.fill") }
                .tag(0)

            GamificationDashboardView()
                .tabItem { Label("Challenges", systemImage: "star.fill") }
                .tag(1)

            StreakCalendarView()
                .tabItem { Label("Streaks", systemImage: "flame.fill") }
                .tag(2)

            RoutineBuilderView()
                .tabItem { Label("Routine", systemImage: "list.clipboard.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(SLTheme.Colors.primary)
        .onAppear { configureTabBarAppearance() }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(SLTheme.Colors.backgroundSecondary)

        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(SLTheme.Colors.textTertiary),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(SLTheme.Colors.primary),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(SLTheme.Colors.textTertiary)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(SLTheme.Colors.primary)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
