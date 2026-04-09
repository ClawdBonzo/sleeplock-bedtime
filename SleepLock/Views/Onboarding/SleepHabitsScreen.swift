import SwiftUI

struct SleepHabitsScreen: View {
    @Binding var selectedHabit: String
    let onNext: () -> Void

    @State private var imageScale: CGFloat = 0.8
    @State private var imageOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var listOpacity: Double = 0
    @State private var listOffset: CGFloat = 18
    @State private var buttonOpacity: Double = 0

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: SLTheme.Spacing.xl) {
                Spacer().frame(height: SLTheme.Spacing.lg)

                // Image
                Image("Onboarding-2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                    .shadow(color: SLTheme.Colors.primary.opacity(0.25), radius: 18, y: 6)
                    .scaleEffect(imageScale)
                    .opacity(imageOpacity)

                // Header
                VStack(spacing: SLTheme.Spacing.xs) {
                    Text("How are your current\nsleep habits?")
                        .font(SLTheme.Typography.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Be honest — no judgment here!")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                // Options
                VStack(spacing: SLTheme.Spacing.sm) {
                    ForEach(Array(SleepHabit.options.enumerated()), id: \.element.id) { index, habit in
                        HabitOptionRow(
                            habit: habit,
                            isSelected: selectedHabit == habit.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedHabit = habit.id
                                }
                                HapticFeedbackEngine.shared.triggerLightTap()
                            }
                        )
                        .offset(y: listOffset)
                        .opacity(listOpacity)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.75)
                                .delay(0.5 + Double(index) * 0.07),
                            value: listOpacity
                        )
                    }
                }

                Spacer()

                SLPrimaryButton("Continue", icon: "arrow.right") { onNext() }
                    .opacity(selectedHabit.isEmpty ? 0.45 : 1)
                    .scaleEffect(selectedHabit.isEmpty ? 0.97 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedHabit.isEmpty)
                    .disabled(selectedHabit.isEmpty)
                    .opacity(buttonOpacity)
                    .padding(.bottom, SLTheme.Spacing.xxl)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.65).delay(0.1)) {
                imageScale = 1.0
                imageOpacity = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                titleOffset = 0
                titleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.45)) {
                listOffset = 0
                listOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.9)) {
                buttonOpacity = 1
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
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

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
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .padding(SLTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .fill(isSelected ? SLTheme.Colors.primary.opacity(0.12) : SLTheme.Colors.backgroundTertiary)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .stroke(isSelected ? SLTheme.Colors.primary : Color.clear, lineWidth: 1.5)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
        }
    }
}
