import SwiftUI
import SwiftData

struct MainTabView: View {
    @Bindable var streakService: SleepStreakService
    @State private var selectedTab: Int = {
        #if DEBUG
        if let idx = CommandLine.arguments.firstIndex(of: "-StartTab"),
           idx + 1 < CommandLine.arguments.count,
           let n = Int(CommandLine.arguments[idx + 1]) { return n }
        #endif
        return 0
    }()
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    private var isPremium: Bool { PurchaseService.shared.isPremium }
    private var userName: String { profiles.first?.displayName ?? "" }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(streakService: streakService)
                .tabItem { Label("Home", systemImage: "moon.stars.fill") }
                .tag(0)

            GamificationDashboardView()
                .proGated(.gamification, isPremium: isPremium, userName: userName)
                .tabItem { Label("Challenges", systemImage: "star.fill") }
                .tag(1)

            StreakCalendarView()
                .proGated(.streaks, isPremium: isPremium, userName: userName)
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
