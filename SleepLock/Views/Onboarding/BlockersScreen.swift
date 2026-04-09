import SwiftUI

struct BlockersScreen: View {
    @Binding var selectedBlockers: [String]
    let onNext: () -> Void

    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = 24
    @State private var gridOpacity: Double = 0
    @State private var gridOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: SLTheme.Spacing.xl) {
                Spacer().frame(height: SLTheme.Spacing.lg)

                // Icon-based header (no duplicate image asset)
                VStack(spacing: SLTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(SLTheme.Colors.warning.opacity(0.12))
                            .frame(width: 88, height: 88)

                        Text("🌃")
                            .font(.system(size: 48))
                    }

                    VStack(spacing: SLTheme.Spacing.xs) {
                        Text("What keeps you\nup at night?")
                            .font(SLTheme.Typography.title)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("Select all that apply — we'll tailor your routine")
                            .font(SLTheme.Typography.subheadline)
                            .foregroundStyle(SLTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .offset(y: headerOffset)
                .opacity(headerOpacity)

                // Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SLTheme.Spacing.sm) {
                    ForEach(Array(SleepBlocker.all.enumerated()), id: \.element.id) { index, blocker in
                        BlockerTile(
                            blocker: blocker,
                            isSelected: selectedBlockers.contains(blocker.id),
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedBlockers.contains(blocker.id) {
                                        selectedBlockers.removeAll { $0 == blocker.id }
                                    } else {
                                        selectedBlockers.append(blocker.id)
                                    }
                                }
                                HapticFeedbackEngine.shared.triggerLightTap()
                            }
                        )
                        .offset(y: gridOffset)
                        .opacity(gridOpacity)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.75)
                                .delay(0.45 + Double(index) * 0.055),
                            value: gridOpacity
                        )
                    }
                }
                .offset(y: gridOffset)
                .opacity(gridOpacity)

                Spacer()

                VStack(spacing: SLTheme.Spacing.sm) {
                    SLPrimaryButton("Continue", icon: "arrow.right") { onNext() }
                        .opacity(selectedBlockers.isEmpty ? 0.45 : 1)
                        .scaleEffect(selectedBlockers.isEmpty ? 0.97 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedBlockers.isEmpty)
                        .disabled(selectedBlockers.isEmpty)

                    Button("Skip for now") { onNext() }
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                }
                .opacity(buttonOpacity)
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.15)) {
                headerOffset = 0
                headerOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
                gridOffset = 0
                gridOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(1.0)) {
                buttonOpacity = 1
            }
        }
    }
}

private struct BlockerTile: View {
    let blocker: SleepBlocker
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: SLTheme.Spacing.xs) {
                Image(systemName: blocker.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? SLTheme.Colors.primary : SLTheme.Colors.textSecondary)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                Text(blocker.title)
                    .font(SLTheme.Typography.captionBold)
                    .foregroundStyle(.white)

                Text(blocker.description)
                    .font(.system(size: 10))
                    .foregroundStyle(SLTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SLTheme.Spacing.md)
            .padding(.horizontal, SLTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .fill(isSelected ? SLTheme.Colors.primary.opacity(0.15) : SLTheme.Colors.backgroundTertiary)
                    .animation(.easeInOut(duration: 0.18), value: isSelected)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .stroke(isSelected ? SLTheme.Colors.primary : Color.clear, lineWidth: 1.5)
                    .animation(.easeInOut(duration: 0.18), value: isSelected)
            )
        }
    }
}
