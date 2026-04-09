import SwiftUI

struct BedtimePickerScreen: View {
    @Binding var bedtime: Date
    @Binding var wakeTime: Date
    let onNext: () -> Void

    @State private var imageScale: CGFloat = 0.8
    @State private var imageOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var pickersOpacity: Double = 0
    @State private var pickersOffset: CGFloat = 24
    @State private var buttonOpacity: Double = 0

    private var sleepDuration: String {
        let interval = wakeTime.timeIntervalSince(bedtime)
        let adjusted = interval < 0 ? interval + 86400 : interval
        let hours = Int(adjusted) / 3600
        let minutes = (Int(adjusted) % 3600) / 60
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours) hours"
    }

    var body: some View {
        SLOnboardingPage {
            VStack(spacing: SLTheme.Spacing.xl) {
                Spacer().frame(height: SLTheme.Spacing.lg)

                // Header
                VStack(spacing: SLTheme.Spacing.md) {
                    Image("Onboarding-3")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 160)
                        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                        .shadow(color: SLTheme.Colors.primary.opacity(0.25), radius: 18, y: 6)
                        .scaleEffect(imageScale)
                        .opacity(imageOpacity)

                    VStack(spacing: SLTheme.Spacing.xs) {
                        Text("Set Your Bedtime\nCommitment")
                            .font(SLTheme.Typography.title)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("This is the time you'll aim to be in bed")
                            .font(SLTheme.Typography.subheadline)
                            .foregroundStyle(SLTheme.Colors.textSecondary)
                    }
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
                }

                // Pickers
                VStack(spacing: SLTheme.Spacing.lg) {
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
                }
                .offset(y: pickersOffset)
                .opacity(pickersOpacity)

                Spacer()

                SLPrimaryButton("Lock It In", icon: "lock.fill") { onNext() }
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
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.45)) {
                pickersOffset = 0
                pickersOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.75)) {
                buttonOpacity = 1
            }
        }
    }
}
