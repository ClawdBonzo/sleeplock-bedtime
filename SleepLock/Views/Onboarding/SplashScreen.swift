import SwiftUI

struct SplashScreen: View {
    let onStart: () -> Void
    @State private var moonOffset: CGFloat = 50
    @State private var titleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: SLTheme.Spacing.xxl) {
                Spacer()

                // Moon illustration
                ZStack {
                    // Glow
                    Circle()
                        .fill(SLTheme.Colors.moonGlow.opacity(0.15))
                        .frame(width: 220, height: 220)
                        .blur(radius: 30)

                    // Moon
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [SLTheme.Colors.moonGlow, SLTheme.Colors.primaryLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: SLTheme.Colors.moonGlow.opacity(0.5), radius: 20)
                }
                .offset(y: moonOffset)

                VStack(spacing: SLTheme.Spacing.md) {
                    Text("SleepLock")
                        .font(SLTheme.Typography.largeTitle)
                        .foregroundStyle(.white)

                    Text("Start Your Energized Life")
                        .font(SLTheme.Typography.title3)
                        .foregroundStyle(SLTheme.Colors.primaryLight)

                    Text("Build a consistent bedtime.\nTrack your streak. Wake up powerful.")
                        .font(SLTheme.Typography.body)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, SLTheme.Spacing.xs)
                }
                .opacity(titleOpacity)

                Spacer()

                VStack(spacing: SLTheme.Spacing.md) {
                    SLPrimaryButton("Begin Your Transformation", icon: "sparkles") {
                        onStart()
                    }

                    Text("Takes just 2 minutes to set up")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                }
                .opacity(buttonOpacity)
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                moonOffset = 0
            }
            withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
                titleOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.9)) {
                buttonOpacity = 1
            }
        }
    }
}
