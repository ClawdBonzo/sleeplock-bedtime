import SwiftUI

struct SplashScreen: View {
    let onStart: () -> Void

    @State private var pulse = false
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var ring1Scale: CGFloat = 0.6
    @State private var ring2Scale: CGFloat = 0.6
    @State private var ring1Opacity: Double = 0
    @State private var ring2Opacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 40
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 30
    @State private var starsVisible = false

    var body: some View {
        ZStack {
            // Radial bg glow
            RadialGradient(
                colors: [SLTheme.Colors.primary.opacity(0.25), Color.clear],
                center: .center,
                startRadius: 40,
                endRadius: 280
            )
            .ignoresSafeArea()
            .scaleEffect(pulse ? 1.15 : 1.0)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulse)

            VStack(spacing: 0) {
                Spacer()

                // Orbital rings + icon
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(SLTheme.Colors.primary.opacity(0.12), lineWidth: 1)
                        .frame(width: 200, height: 200)
                        .scaleEffect(ring2Scale)
                        .opacity(ring2Opacity)

                    // Inner ring
                    Circle()
                        .stroke(SLTheme.Colors.primaryLight.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 140, height: 140)
                        .scaleEffect(ring1Scale)
                        .opacity(ring1Opacity)

                    // Glow disc
                    Circle()
                        .fill(SLTheme.Colors.primary.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)

                    // Brand icon
                    Image("BrandIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: SLTheme.Colors.primary.opacity(0.6), radius: 20)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)

                    // Orbiting dot
                    if ring1Opacity > 0.5 {
                        Circle()
                            .fill(SLTheme.Colors.accent)
                            .frame(width: 8, height: 8)
                            .offset(x: 70)
                            .rotationEffect(.degrees(pulse ? 360 : 0))
                            .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: pulse)
                    }
                }

                Spacer().frame(height: 48)

                // Title block
                VStack(spacing: 12) {
                    Text("SleepLock")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, SLTheme.Colors.primaryLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Start Your Energized Life")
                        .font(SLTheme.Typography.title3)
                        .foregroundStyle(SLTheme.Colors.primaryLight)

                    Text("Build a consistent bedtime.\nTrack your streak. Wake up powerful.")
                        .font(SLTheme.Typography.body)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(subtitleOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer()

                // CTA
                VStack(spacing: SLTheme.Spacing.md) {
                    Button(action: onStart) {
                        HStack(spacing: SLTheme.Spacing.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Begin Your Transformation")
                                .font(SLTheme.Typography.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            LinearGradient(
                                colors: [SLTheme.Colors.primary, Color(hex: "8B5CF6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
                        .shadow(color: SLTheme.Colors.primary.opacity(0.5), radius: 16, y: 6)
                    }

                    Text("Takes just 2 minutes · No credit card needed")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .offset(y: buttonOffset)
                .opacity(buttonOpacity)
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
        }
        .onAppear {
            // Staggered entrance sequence
            withAnimation(.spring(response: 0.8, dampingFraction: 0.55).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1
            }
            withAnimation(.spring(response: 0.9, dampingFraction: 0.65).delay(0.3)) {
                ring1Scale = 1.0
                ring1Opacity = 1
            }
            withAnimation(.spring(response: 1.0, dampingFraction: 0.65).delay(0.45)) {
                ring2Scale = 1.0
                ring2Opacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.6)) {
                titleOffset = 0
                titleOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.9)) {
                subtitleOpacity = 1
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(1.0)) {
                buttonOffset = 0
                buttonOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pulse = true
            }
        }
    }
}
