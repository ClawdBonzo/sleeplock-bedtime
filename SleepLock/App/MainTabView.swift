import SwiftUI

struct MainTabView: View {
    @Bindable var streakService: SleepStreakService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(streakService: streakService)
                .tabItem {
                    Image("Tab-Dashboard").renderingMode(.template)
                    Text("Home")
                }
                .tag(0)

            StreakCalendarView()
                .tabItem {
                    Image("Tab-Streaks").renderingMode(.template)
                    Text("Streaks")
                }
                .tag(1)

            ProgressChartsView()
                .tabItem {
                    Image("Tab-Logger").renderingMode(.template)
                    Text("Progress")
                }
                .tag(2)

            RoutineBuilderView()
                .tabItem {
                    Image("Tab-Routines").renderingMode(.template)
                    Text("Routine")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Image("Tab-Settings").renderingMode(.template)
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(SLTheme.Colors.primary)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(SLTheme.Colors.backgroundSecondary)

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(SLTheme.Colors.textTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(SLTheme.Colors.textTertiary)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(SLTheme.Colors.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(SLTheme.Colors.primary)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
