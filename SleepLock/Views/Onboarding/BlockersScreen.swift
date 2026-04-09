import SwiftUI

struct BlockersScreen: View {
    @Binding var selectedBlockers: [String]
    let onNext: () -> Void

    @State private var appeared = false

    // Per-blocker accent colors matching the SF Symbol icons
    private let blockerColors: [Color] = [
        Color(hex: "4F88FF"),   // Screen Time - blue
        Color(hex: "FF9F0A"),   // Caffeine - orange
        Color(hex: "BF5AF2"),   // Stress - purple
        Color(hex: "64D2FF"),   // Irregular - teal
        Color(hex: "FF375F"),   // Noise - red
        Color(hex: "30D158"),   // Late Eating - green
        Color(hex: "FF6B35"),   // Late Exercise - deep orange
        Color(hex: "FFD60A"),   // Long Naps - yellow
    ]

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [SLTheme.Colors.warning.opacity(0.12), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.2),
                startRadius: 10,
                endRadius: 240
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: SLTheme.Spacing.lg)

                // Header
                VStack(spacing: SLTheme.Spacing.sm) {
                    Image(systemName: "moon.haze.fill")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [SLTheme.Colors.warning, SLTheme.Colors.primaryLight],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: SLTheme.Colors.warning.opacity(0.35), radius: 12)
                        .scaleEffect(appeared ? 1 : 0.4)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.05), value: appeared)

                    Text("What keeps you\nup at night?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .offset(y: appeared ? 0 : 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25), value: appeared)

                    Text("Select all that apply")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                        .offset(y: appeared ? 0 : 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.35), value: appeared)
                }

                Spacer().frame(height: SLTheme.Spacing.lg)

                // Blockers grid
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: SLTheme.Spacing.sm), GridItem(.flexible(), spacing: SLTheme.Spacing.sm)],
                    spacing: SLTheme.Spacing.sm
                ) {
                    ForEach(Array(SleepBlocker.all.enumerated()), id: \.element.id) { index, blocker in
                        let accentColor = blockerColors[index % blockerColors.count]
                        BlockerCell(
                            blocker: blocker,
                            accentColor: accentColor,
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
                        .offset(y: appeared ? 0 : 28)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.75)
                                .delay(0.4 + Double(index) * 0.06),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, SLTheme.Spacing.xl)

                Spacer()

                // CTA
                VStack(spacing: SLTheme.Spacing.sm) {
                    Button(action: onNext) {
                        HStack(spacing: SLTheme.Spacing.sm) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Continue")
                                .font(SLTheme.Typography.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background {
                            if selectedBlockers.isEmpty {
                                Color(hex: "2A2A5A")
                            } else {
                                LinearGradient(
                                    colors: [SLTheme.Colors.primary, Color(hex: "8B5CF6")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
                        .shadow(color: selectedBlockers.isEmpty ? .clear : SLTheme.Colors.primary.opacity(0.4), radius: 12, y: 4)
                    }
                    .disabled(selectedBlockers.isEmpty)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedBlockers.isEmpty)

                    Button("Skip this step") { onNext() }
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .padding(.bottom, SLTheme.Spacing.xxl)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(1.0), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

private struct BlockerCell: View {
    let blocker: SleepBlocker
    let accentColor: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: SLTheme.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: SLTheme.Radius.sm)
                        .fill(isSelected ? accentColor.opacity(0.22) : SLTheme.Colors.backgroundTertiary)
                        .frame(width: 44, height: 44)

                    Image(systemName: blocker.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? accentColor : SLTheme.Colors.textSecondary)
                }
                .scaleEffect(isSelected ? 1.08 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)

                Text(blocker.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(blocker.description)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(SLTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SLTheme.Spacing.md)
            .padding(.horizontal, SLTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .fill(isSelected ? accentColor.opacity(0.1) : SLTheme.Colors.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                            .stroke(isSelected ? accentColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )
            )
            .animation(.easeInOut(duration: 0.18), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
