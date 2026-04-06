import SwiftUI
import SwiftData

@main
struct SleepLockApp: App {
    @State private var showSplash = true

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
        .modelContainer(for: [
            UserProfile.self,
            SleepLogEntry.self,
            RoutineStep.self
        ])
    }
}

// MARK: - Animated Splash Screen
struct AnimatedSplashScreen: View {
    let onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background — use the splash image
            Image(colorScheme == .dark ? "Splash-Dark" : "Splash-Dark")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            // Fallback gradient behind image
            SLTheme.Colors.backgroundPrimary
                .ignoresSafeArea()
                .zIndex(-1)

            VStack(spacing: SLTheme.Spacing.xl) {
                Spacer()

                ZStack {
                    // Glow behind icon
                    Circle()
                        .fill(SLTheme.Colors.moonGlow.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                        .opacity(glowOpacity)

                    // Brand icon
                    Image("BrandIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: SLTheme.Colors.primary.opacity(0.5), radius: 24, y: 4)
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
            withAnimation(.easeOut(duration: 0.6)) {
                logoOpacity = 1
                logoScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                glowOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.4)) {
                titleOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onFinished()
            }
        }
    }
}
