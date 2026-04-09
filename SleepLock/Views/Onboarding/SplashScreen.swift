import SwiftUI

struct SplashScreen: View {
    let onStart: () -> Void

    @State private var imageScale: CGFloat = 0.75
    @State private var imageOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.85
    @State private var buttonOpacity: Double = 0

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: 0) {
                Spacer()

                // Hero image with glow ring
                ZStack {
                    Circle()
                        .fill(SLTheme.Colors.primary.opacity(0.18))
                        .frame(width: 220, height: 220)
                        .blur(radius: glowRadius)

                    Image("Onboarding-1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
                        .shadow(color: SLTheme.Colors.primary.opacity(0.35), radius: 24, y: 10)
                }
                .scaleEffect(imageScale)
                .opacity(imageOpacity)

                Spacer().frame(height: SLTheme.Spacing.xxl)

                // Title block
                VStack(spacing: SLTheme.Spacing.sm) {
                    Text("SleepLock")
                        .font(SLTheme.Typography.largeTitle)
                        .foregroundStyle(.white)

                    Text("Start Your Energized Life")
                        .font(SLTheme.Typography.title3)
                        .foregroundStyle(SLTheme.Colors.primaryLight)
                        .opacity(subtitleOpacity)

                    Text("Build a consistent bedtime.\nTrack your streak. Wake up powerful.")
                        .font(SLTheme.Typography.body)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, SLTheme.Spacing.xxs)
                        .opacity(subtitleOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer()

                // CTA
                VStack(spacing: SLTheme.Spacing.md) {
                    SLPrimaryButton("Begin Your Transformation", icon: "sparkles") {
                        onStart()
                    }

                    Text("Takes just 2 minutes to set up")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                }
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
        }
        .onAppear {
            // Hero pops in with spring
            withAnimation(.spring(response: 0.75, dampingFraction: 0.6).delay(0.1)) {
                imageScale = 1.0
                imageOpacity = 1
            }
            // Glow expands
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                glowRadius = 30
            }
            // Title slides up
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.45)) {
                titleOffset = 0
                titleOpacity = 1
            }
            // Subtitle fades in after title
            withAnimation(.easeIn(duration: 0.5).delay(0.75)) {
                subtitleOpacity = 1
            }
            // Button bounces in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.9)) {
                buttonScale = 1.0
                buttonOpacity = 1
            }
        }
    }
}
