import SwiftUI

struct BedtimePickerScreen: View {
    @Binding var bedtime: Date
    @Binding var wakeTime: Date
    let onNext: () -> Void

    @State private var appeared = false

    private var sleepDuration: String {
        let interval = wakeTime.timeIntervalSince(bedtime)
        let adjusted = interval < 0 ? interval + 86400 : interval
        let hours = Int(adjusted) / 3600
        let minutes = (Int(adjusted) % 3600) / 60
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours) hours"
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [SLTheme.Colors.sleepBlue.opacity(0.18), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.2),
                startRadius: 10,
                endRadius: 260
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: SLTheme.Spacing.lg)

                // Header
                VStack(spacing: SLTheme.Spacing.sm) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [SLTheme.Colors.primaryLight, SLTheme.Colors.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: SLTheme.Colors.primary.opacity(0.5), radius: 14)
                        .scaleEffect(appeared ? 1 : 0.4)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.05), value: appeared)

                    Text("Set Your Bedtime\nCommitment")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .offset(y: appeared ? 0 : 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25), value: appeared)

                    Text("This is the time you'll aim to be in bed")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                        .offset(y: appeared ? 0 : 16)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.35), value: appeared)
                }

                Spacer().frame(height: SLTheme.Spacing.lg)

                // Pickers
                VStack(spacing: SLTheme.Spacing.md) {
                    // Bedtime picker
                    VStack(spacing: 0) {
                        HStack(spacing: SLTheme.Spacing.xs) {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SLTheme.Colors.primaryLight)
                            Text("Bedtime")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(SLTheme.Colors.primaryLight)
                            Spacer()
                        }
                        .padding(.horizontal, SLTheme.Spacing.md)
                        .padding(.vertical, SLTheme.Spacing.sm)
                        .background(SLTheme.Colors.backgroundTertiary)
                        .clipShape(UnevenRoundedRectangle(
                            topLeadingRadius: SLTheme.Radius.lg,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: SLTheme.Radius.lg
                        ))

                        DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 120)
                            .colorScheme(.dark)
                            .clipped()
                            .background(SLTheme.Colors.backgroundTertiary)
                            .clipShape(UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: SLTheme.Radius.lg,
                                bottomTrailingRadius: SLTheme.Radius.lg,
                                topTrailingRadius: 0
                            ))
                    }

                    // Wake up picker
                    VStack(spacing: 0) {
                        HStack(spacing: SLTheme.Spacing.xs) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SLTheme.Colors.accent)
                            Text("Wake Up")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(SLTheme.Colors.accent)
                            Spacer()
                        }
                        .padding(.horizontal, SLTheme.Spacing.md)
                        .padding(.vertical, SLTheme.Spacing.sm)
                        .background(SLTheme.Colors.backgroundTertiary)
                        .clipShape(UnevenRoundedRectangle(
                            topLeadingRadius: SLTheme.Radius.lg,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: SLTheme.Radius.lg
                        ))

                        DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 120)
                            .colorScheme(.dark)
                            .clipped()
                            .background(SLTheme.Colors.backgroundTertiary)
                            .clipShape(UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: SLTheme.Radius.lg,
                                bottomTrailingRadius: SLTheme.Radius.lg,
                                topTrailingRadius: 0
                            ))
                    }

                    // Duration badge
                    HStack(spacing: SLTheme.Spacing.xs) {
                        Image(systemName: "clock.fill").foregroundStyle(SLTheme.Colors.energyGreen)
                        Text("Sleep duration: \(sleepDuration)")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, SLTheme.Spacing.sm)
                    .padding(.horizontal, SLTheme.Spacing.md)
                    .background(SLTheme.Colors.energyGreen.opacity(0.15))
                    .clipShape(Capsule())
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.65), value: appeared)
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .offset(y: appeared ? 0 : 28)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.45), value: appeared)

                Spacer()

                Button(action: onNext) {
                    HStack(spacing: SLTheme.Spacing.sm) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Lock It In")
                            .font(SLTheme.Typography.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        LinearGradient(
                            colors: [SLTheme.Colors.primary, Color(hex: "8B5CF6")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
                    .shadow(color: SLTheme.Colors.primary.opacity(0.4), radius: 12, y: 4)
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .padding(.bottom, SLTheme.Spacing.xxl)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.85), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}
