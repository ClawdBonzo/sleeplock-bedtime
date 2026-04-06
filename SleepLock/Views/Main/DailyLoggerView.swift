import SwiftUI
import SwiftData

struct DailyLoggerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var actualBedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
    @State private var actualWakeTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var energyRating: Int = 3
    @State private var notes: String = ""
    @State private var showSuccess = false

    private var profile: UserProfile? { profiles.first }

    private var hitTarget: Bool {
        guard let profile else { return false }
        let targetComps = profile.targetBedtime.hourMinuteComponents
        let actualComps = actualBedtime.hourMinuteComponents
        let targetMinutes = targetComps.hour * 60 + targetComps.minute
        let actualMinutes = actualComps.hour * 60 + actualComps.minute
        // Within 15 minute grace period
        return actualMinutes <= targetMinutes + 15
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SLTheme.Colors.backgroundPrimary.ignoresSafeArea()

                if showSuccess {
                    successView
                } else {
                    logFormView
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }
            }
            .toolbarBackground(SLTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Log Form
    private var logFormView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: SLTheme.Spacing.xl) {
                // Date header
                SLCard {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(SLTheme.Colors.primary)
                        Text("Logging for last night")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text(Date().isToday ? "Today" : Date().monthDay)
                            .font(SLTheme.Typography.subheadline)
                            .foregroundStyle(SLTheme.Colors.textSecondary)
                    }
                }

                // Bedtime picker
                SLCard {
                    VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                        Label("What time did you get in bed?", systemImage: "moon.fill")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(SLTheme.Colors.primaryLight)

                        DatePicker("Bedtime", selection: $actualBedtime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .colorScheme(.dark)

                        if let profile {
                            HStack {
                                Image(systemName: hitTarget ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundStyle(hitTarget ? SLTheme.Colors.success : SLTheme.Colors.warning)
                                Text("Target: \(profile.targetBedtime.shortTime)")
                                    .font(SLTheme.Typography.caption)
                                    .foregroundStyle(SLTheme.Colors.textSecondary)
                            }
                        }
                    }
                }

                // Wake time picker
                SLCard {
                    VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                        Label("What time did you wake up?", systemImage: "sun.max.fill")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(SLTheme.Colors.accent)

                        DatePicker("Wake time", selection: $actualWakeTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .colorScheme(.dark)
                    }
                }

                // Energy rating
                SLCard {
                    VStack(spacing: SLTheme.Spacing.md) {
                        Text("How's your energy this morning?")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(.white)

                        HStack(spacing: SLTheme.Spacing.md) {
                            ForEach(EnergyLevel.allCases, id: \.rawValue) { level in
                                VStack(spacing: SLTheme.Spacing.xxs) {
                                    Text(level.emoji)
                                        .font(.system(size: energyRating == level.rawValue ? 40 : 28))
                                        .scaleEffect(energyRating == level.rawValue ? 1.1 : 1)

                                    Text(level.label)
                                        .font(.system(size: 9))
                                        .foregroundStyle(
                                            energyRating == level.rawValue ?
                                            level.color : SLTheme.Colors.textTertiary
                                        )
                                }
                                .frame(maxWidth: .infinity)
                                .onTapGesture {
                                    withAnimation(SLTheme.Animation.bouncy) {
                                        energyRating = level.rawValue
                                    }
                                }
                            }
                        }
                    }
                }

                // Notes
                SLCard {
                    VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                        Label("Notes (optional)", systemImage: "note.text")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(SLTheme.Colors.textSecondary)

                        TextField("How did you sleep?", text: $notes, axis: .vertical)
                            .font(SLTheme.Typography.body)
                            .foregroundStyle(.white)
                            .lineLimit(3...5)
                            .textFieldStyle(.plain)
                    }
                }

                SLPrimaryButton("Save Sleep Log", icon: "checkmark") {
                    saveEntry()
                }
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
            .padding(.horizontal, SLTheme.Spacing.md)
        }
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: SLTheme.Spacing.xxl) {
            Spacer()

            Image(systemName: hitTarget ? "flame.fill" : "moon.fill")
                .font(.system(size: 80))
                .foregroundStyle(hitTarget ? SLTheme.Colors.streakGold : SLTheme.Colors.primaryLight)
                .shadow(color: (hitTarget ? SLTheme.Colors.streakGold : SLTheme.Colors.primary).opacity(0.4), radius: 20)

            VStack(spacing: SLTheme.Spacing.sm) {
                Text(hitTarget ? "Streak Alive!" : "Logged!")
                    .font(SLTheme.Typography.title)
                    .foregroundStyle(.white)

                Text(hitTarget ?
                     "You hit your bedtime target. Keep it going!" :
                     "Sleep logged. Try to hit your target tonight!")
                    .font(SLTheme.Typography.body)
                    .foregroundStyle(SLTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            SLPrimaryButton("Done") { dismiss() }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .padding(.bottom, SLTheme.Spacing.xxl)
        }
    }

    // MARK: - Save
    private func saveEntry() {
        let entry = SleepLogEntry(
            date: Date(),
            actualBedtime: actualBedtime,
            actualWakeTime: actualWakeTime,
            targetBedtime: profile?.targetBedtime ?? actualBedtime,
            morningEnergyRating: energyRating,
            notes: notes,
            hitTarget: hitTarget
        )
        modelContext.insert(entry)
        try? modelContext.save()

        withAnimation(SLTheme.Animation.spring) {
            showSuccess = true
        }
    }
}
