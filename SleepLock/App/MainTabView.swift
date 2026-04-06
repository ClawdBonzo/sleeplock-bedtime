import SwiftUI

struct MainTabView: View {
    @Bindable var streakService: SleepStreakService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(streakService: streakService)
                .tabItem {
                    Image(systemName: "moon.stars.fill")
                    Text("Home")
                }
                .tag(0)

            StreakCalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(1)

            ProgressChartsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(2)

            RoutineBuilderView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard.fill")
                    Text("Routine")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
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
