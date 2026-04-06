import SwiftUI

struct BedtimePickerScreen: View {
    @Binding var bedtime: Date
    @Binding var wakeTime: Date
    let onNext: () -> Void

    private var sleepDuration: String {
        let interval = wakeTime.timeIntervalSince(bedtime)
        let adjusted = interval < 0 ? interval + 86400 : interval
        let hours = Int(adjusted) / 3600
        let minutes = (Int(adjusted) % 3600) / 60
        if minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(hours) hours"
    }

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: SLTheme.Spacing.xl) {
                Spacer().frame(height: SLTheme.Spacing.lg)

                VStack(spacing: SLTheme.Spacing.md) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(SLTheme.Colors.sleepBlue)

                    Text("Set Your Bedtime\nCommitment")
                        .font(SLTheme.Typography.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("This is the time you'll aim to be in bed")
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                VStack(spacing: SLTheme.Spacing.lg) {
                    // Bedtime picker
                    VStack(spacing: SLTheme.Spacing.xs) {
                        Label("Bedtime", systemImage: "moon.fill")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(SLTheme.Colors.primaryLight)

                        DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 100)
                            .colorScheme(.dark)
                    }
                    .padding(SLTheme.Spacing.md)
                    .background(SLTheme.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))

                    // Wake time picker
                    VStack(spacing: SLTheme.Spacing.xs) {
                        Label("Wake Up", systemImage: "sun.max.fill")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(SLTheme.Colors.accent)

                        DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 100)
                            .colorScheme(.dark)
                    }
                    .padding(SLTheme.Spacing.md)
                    .background(SLTheme.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))

                    // Sleep duration badge
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(SLTheme.Colors.energyGreen)
                        Text("Sleep duration: \(sleepDuration)")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, SLTheme.Spacing.sm)
                    .padding(.horizontal, SLTheme.Spacing.md)
                    .background(SLTheme.Colors.energyGreen.opacity(0.15))
                    .clipShape(Capsule())
                }

                Spacer()

                SLPrimaryButton("Lock It In", icon: "lock.fill") {
                    onNext()
                }
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
        }
    }
}
