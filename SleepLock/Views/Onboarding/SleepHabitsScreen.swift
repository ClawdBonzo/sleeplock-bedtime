import SwiftUI

struct SleepHabitsScreen: View {
    @Binding var selectedHabit: String
    let onNext: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Ambient glow
            RadialGradient(
                colors: [SLTheme.Colors.sleepBlue.opacity(0.15), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.25),
                startRadius: 10,
                endRadius: 250
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: SLTheme.Spacing.xl)

                // Header
                VStack(spacing: SLTheme.Spacing.sm) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [SLTheme.Colors.primaryLight, SLTheme.Colors.sleepBlue],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: SLTheme.Colors.sleepBlue.opacity(0.4), radius: 12)
                        .scaleEffect(appeared ? 1 : 0.4)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.05), value: appeared)

                    Text("How are your current\nsleep habits?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .offset(y: appeared ? 0 : 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25), value: appeared)

                    Text("Be honest — no judgment here!")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                        .offset(y: appeared ? 0 : 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.35), value: appeared)
                }

                Spacer().frame(height: SLTheme.Spacing.xl)

                // Habit options
                VStack(spacing: SLTheme.Spacing.sm) {
                    ForEach(Array(SleepHabit.options.enumerated()), id: \.element.id) { index, habit in
                        HabitRow(
                            habit: habit,
                            isSelected: selectedHabit == habit.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedHabit = habit.id
                                }
                                HapticFeedbackEngine.shared.triggerLightTap()
                            }
                        )
                        .offset(y: appeared ? 0 : 30)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.75)
                                .delay(0.4 + Double(index) * 0.08),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, SLTheme.Spacing.xl)

                Spacer()

                // CTA
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
                        if selectedHabit.isEmpty {
                            Color(hex: "2A2A5A")
                        } else {
                            LinearGradient(
                                colors: [SLTheme.Colors.primary, Color(hex: "8B5CF6")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
                    .shadow(color: selectedHabit.isEmpty ? .clear : SLTheme.Colors.primary.opacity(0.4), radius: 12, y: 4)
                }
                .disabled(selectedHabit.isEmpty)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedHabit.isEmpty)
                .padding(.horizontal, SLTheme.Spacing.xl)
                .padding(.bottom, SLTheme.Spacing.xxl)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.95), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

private struct HabitRow: View {
    let habit: SleepHabit
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: SLTheme.Spacing.md) {
                Image(systemName: habit.emoji)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? SLTheme.Colors.primaryLight : SLTheme.Colors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? SLTheme.Colors.primary.opacity(0.2) : SLTheme.Colors.backgroundTertiary)
                    )
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(SLTheme.Typography.headline)
                        .foregroundStyle(.white)
                    Text(habit.description)
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? SLTheme.Colors.primary : SLTheme.Colors.textTertiary.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(SLTheme.Colors.primary)
                            .frame(width: 14, height: 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isSelected)
            }
            .padding(.horizontal, SLTheme.Spacing.md)
            .padding(.vertical, SLTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .fill(isSelected ? SLTheme.Colors.primary.opacity(0.1) : SLTheme.Colors.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                            .stroke(isSelected ? SLTheme.Colors.primary.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
