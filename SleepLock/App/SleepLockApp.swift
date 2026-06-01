import SwiftUI
import SwiftData
import RevenueCat

@main
struct SleepLockApp: App {
    @State private var showSplash = true

    let sharedContainer: ModelContainer

    init() {
        PurchaseService.shared.configure()

        let schema = Schema([
            UserProfile.self,
            SleepLogEntry.self,
            RoutineStep.self,
            GamificationProfile.self,
            Quest.self,
            Badge.self
        ])
        let config = ModelConfiguration(schema: schema)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [config])
        DemoSeeder.seedIfRequested(container: container)
        self.sharedContainer = container
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    AnimatedSplashScreen {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .modelContainer(sharedContainer)
    }
}

// MARK: - Animated Splash Screen
struct AnimatedSplashScreen: View {
    let onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Background
            SLTheme.Colors.backgroundPrimary
                .ignoresSafeArea()

            StarsBackground()
                .ignoresSafeArea()

            // Radial glow
            RadialGradient(
                colors: [SLTheme.Colors.primary.opacity(0.25), Color.clear],
                center: .center,
                startRadius: 40,
                endRadius: 300
            )
            .ignoresSafeArea()
            .scaleEffect(pulse ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulse)

            VStack(spacing: SLTheme.Spacing.xl) {
                Spacer()

                ZStack {
                    // Glow behind icon
                    Circle()
                        .fill(SLTheme.Colors.moonGlow.opacity(0.25))
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                        .opacity(glowOpacity)

                    // Brand icon
                    Image("BrandIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: SLTheme.Colors.primary.opacity(0.6), radius: 28, y: 4)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: SLTheme.Spacing.xs) {
                    Text("SleepLock")
                        .font(SLTheme.Typography.largeTitle)
                        .foregroundStyle(.white)

                    Text("Lock in your best sleep")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }
                .opacity(titleOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                logoOpacity = 1
                logoScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                glowOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.4)) {
                titleOpacity = 1
            }

            pulse = true

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.0))
                onFinished()
            }
        }
    }
}
