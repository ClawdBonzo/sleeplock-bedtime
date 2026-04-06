import SwiftUI

struct BlockersScreen: View {
    @Binding var selectedBlockers: [String]
    let onNext: () -> Void

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: SLTheme.Spacing.xl) {
                Spacer().frame(height: SLTheme.Spacing.xxl)

                VStack(spacing: SLTheme.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(SLTheme.Colors.accent)

                    Text("What keeps you\nup at night?")
                        .font(SLTheme.Typography.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Select all that apply — we'll tailor your routine")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SLTheme.Spacing.sm) {
                    ForEach(SleepBlocker.all) { blocker in
                        BlockerTile(
                            blocker: blocker,
                            isSelected: selectedBlockers.contains(blocker.id),
                            onTap: {
                                withAnimation(SLTheme.Animation.quick) {
                                    if selectedBlockers.contains(blocker.id) {
                                        selectedBlockers.removeAll { $0 == blocker.id }
                                    } else {
                                        selectedBlockers.append(blocker.id)
                                    }
                                }
                            }
                        )
                    }
                }

                Spacer()

                VStack(spacing: SLTheme.Spacing.sm) {
                    SLPrimaryButton("Continue", icon: "arrow.right") {
                        onNext()
                    }
                    .opacity(selectedBlockers.isEmpty ? 0.5 : 1)
                    .disabled(selectedBlockers.isEmpty)

                    Button("Skip for now") {
                        onNext()
                    }
                    .font(SLTheme.Typography.subheadline)
                    .foregroundStyle(SLTheme.Colors.textTertiary)
                }
                .padding(.bottom, SLTheme.Spacing.xxl)
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
            .background(isSelected ? SLTheme.Colors.primary.opacity(0.15) : SLTheme.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .stroke(isSelected ? SLTheme.Colors.primary : Color.clear, lineWidth: 1.5)
            )
        }
    }
}
