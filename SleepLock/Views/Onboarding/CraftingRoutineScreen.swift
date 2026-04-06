import SwiftUI

struct CraftingRoutineScreen: View {
    let name: String
    let onComplete: () -> Void

    @State private var progress: Double = 0
    @State private var currentPhase = 0
    @State private var showComplete = false

    private let phases = [
        ("Analyzing your sleep patterns", "brain.head.profile"),
        ("Building your wind-down routine", "moon.haze.fill"),
        ("Optimizing notification timing", "bell.badge.fill"),
        ("Personalizing your streak goals", "flame.fill"),
        ("Finalizing your sleep plan", "checkmark.seal.fill")
    ]

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: SLTheme.Spacing.xxl) {
                Spacer()

                if !showComplete {
                    // Crafting animation
                    VStack(spacing: SLTheme.Spacing.xxl) {
                        ZStack {
                            Circle()
                                .fill(SLTheme.Colors.primary.opacity(0.1))
                                .frame(width: 160, height: 160)

                            SLProgressRing(
                                progress: progress,
                                lineWidth: 6,
                                size: 140,
                                color: SLTheme.Colors.primary
                            )

                            Image(systemName: phases[currentPhase].1)
                                .font(.system(size: 44))
                                .foregroundStyle(SLTheme.Colors.primaryLight)
                                .contentTransition(.symbolEffect(.replace))
                        }

                        VStack(spacing: SLTheme.Spacing.md) {
                            Text("Crafting your perfect\nsleep routine for \(name)...")
                                .font(SLTheme.Typography.title2)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text(phases[currentPhase].0)
                                .font(SLTheme.Typography.subheadline)
                                .foregroundStyle(SLTheme.Colors.textSecondary)
                                .contentTransition(.numericText())
                        }

                        // Progress bars for each phase
                        VStack(spacing: SLTheme.Spacing.sm) {
                            ForEach(0..<phases.count, id: \.self) { index in
                                HStack(spacing: SLTheme.Spacing.sm) {
                                    Image(systemName: index <= currentPhase ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 16))
                                        .foregroundStyle(
                                            index < currentPhase ? SLTheme.Colors.success :
                                            index == currentPhase ? SLTheme.Colors.primary :
                                            SLTheme.Colors.textTertiary
                                        )

                                    Text(phases[index].0)
                                        .font(SLTheme.Typography.footnote)
                                        .foregroundStyle(
                                            index <= currentPhase ? SLTheme.Colors.textPrimary : SLTheme.Colors.textTertiary
                                        )

                                    Spacer()

                                    if index < currentPhase {
                                        Text("Done")
                                            .font(SLTheme.Typography.caption)
                                            .foregroundStyle(SLTheme.Colors.success)
                                    } else if index == currentPhase {
                                        ProgressView()
                                            .tint(SLTheme.Colors.primary)
                                            .scaleEffect(0.7)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, SLTheme.Spacing.md)
                    }
                } else {
                    // Complete state
                    VStack(spacing: SLTheme.Spacing.xl) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(SLTheme.Colors.success)
                            .shadow(color: SLTheme.Colors.success.opacity(0.4), radius: 20)

                        VStack(spacing: SLTheme.Spacing.sm) {
                            Text("Your Sleep Plan\nis Ready!")
                                .font(SLTheme.Typography.title)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text("Let's unlock your best energy yet")
                                .font(SLTheme.Typography.body)
                                .foregroundStyle(SLTheme.Colors.textSecondary)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                if showComplete {
                    SLPrimaryButton("See Your Plan", icon: "sparkles") {
                        onComplete()
                    }
                    .padding(.bottom, SLTheme.Spacing.xxl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startCrafting()
        }
    }

    private func startCrafting() {
        let phaseDuration = 0.7

        for i in 0..<phases.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration * Double(i)) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPhase = i
                    progress = Double(i + 1) / Double(phases.count)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + phaseDuration * Double(phases.count) + 0.3) {
            withAnimation(SLTheme.Animation.spring) {
                showComplete = true
            }
        }
    }
}
