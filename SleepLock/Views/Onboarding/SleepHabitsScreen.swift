import SwiftUI

struct SleepHabitsScreen: View {
    @Binding var selectedHabit: String
    let onNext: () -> Void

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: SLTheme.Spacing.xl) {
                Spacer().frame(height: SLTheme.Spacing.xxl)

                VStack(spacing: SLTheme.Spacing.md) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(SLTheme.Colors.secondary)

                    Text("How are your current\nsleep habits?")
                        .font(SLTheme.Typography.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Be honest — no judgment here!")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                VStack(spacing: SLTheme.Spacing.sm) {
                    ForEach(SleepHabit.options) { habit in
                        HabitOptionRow(
                            habit: habit,
                            isSelected: selectedHabit == habit.id,
                            onTap: {
                                withAnimation(SLTheme.Animation.quick) {
                                    selectedHabit = habit.id
                                }
                            }
                        )
                    }
                }

                Spacer()

                SLPrimaryButton("Continue", icon: "arrow.right") {
                    onNext()
                }
                .opacity(selectedHabit.isEmpty ? 0.5 : 1)
                .disabled(selectedHabit.isEmpty)
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
        }
    }
}

private struct HabitOptionRow: View {
    let habit: SleepHabit
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: SLTheme.Spacing.md) {
                Text(habit.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: SLTheme.Spacing.xxxs) {
                    Text(habit.title)
                        .font(SLTheme.Typography.headline)
                        .foregroundStyle(.white)

                    Text(habit.description)
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? SLTheme.Colors.primary : SLTheme.Colors.textTertiary)
            }
            .padding(SLTheme.Spacing.md)
            .background(isSelected ? SLTheme.Colors.primary.opacity(0.12) : SLTheme.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .stroke(isSelected ? SLTheme.Colors.primary : Color.clear, lineWidth: 1.5)
            )
        }
    }
}
