import SwiftUI
import SwiftData

@main
struct SleepLockApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            UserProfile.self,
            SleepLogEntry.self,
            RoutineStep.self
        ])
    }
}
