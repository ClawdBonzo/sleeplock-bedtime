import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var showResetAlert = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: SLTheme.Spacing.lg) {
                    // Profile section
                    if let profile {
                        SLCard {
                            HStack(spacing: SLTheme.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(SLTheme.Colors.primary.opacity(0.2))
                                        .frame(width: 56, height: 56)

                                    Text(String(profile.displayName.prefix(1)).uppercased())
                                        .font(SLTheme.Typography.title2)
                                        .foregroundStyle(SLTheme.Colors.primary)
                                }

                                VStack(alignment: .leading, spacing: SLTheme.Spacing.xxs) {
                                    Text(profile.displayName)
                                        .font(SLTheme.Typography.headline)
                                        .foregroundStyle(.white)

                                    Text("Member since \(profile.createdAt.monthDay)")
                                        .font(SLTheme.Typography.caption)
                                        .foregroundStyle(SLTheme.Colors.textTertiary)
                                }

                                Spacer()
                            }
                        }
                    }

                    // Bedtime settings
                    SLCard {
                        VStack(alignment: .leading, spacing: SLTheme.Spacing.md) {
                            Label("Sleep Schedule", systemImage: "clock.fill")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(.white)

                            if let profile {
                                SettingsTimeRow(
                                    label: "Bedtime",
                                    icon: "moon.fill",
                                    color: SLTheme.Colors.primaryLight,
                                    time: Binding(
                                        get: { profile.targetBedtime },
                                        set: {
                                            profile.targetBedtime = $0
                                            try? modelContext.save()
                                            updateNotifications(profile)
                                        }
                                    )
                                )

                                Divider().background(Color.white.opacity(0.06))

                                SettingsTimeRow(
                                    label: "Wake Time",
                                    icon: "sun.max.fill",
                                    color: SLTheme.Colors.accent,
                                    time: Binding(
                                        get: { profile.targetWakeTime },
                                        set: {
                                            profile.targetWakeTime = $0
                                            try? modelContext.save()
                                            updateNotifications(profile)
                                        }
                                    )
                                )
                            }
                        }
                    }

                    // Notifications
                    SLCard {
                        VStack(alignment: .leading, spacing: SLTheme.Spacing.md) {
                            Label("Notifications", systemImage: "bell.fill")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(.white)

                            if let profile {
                                Toggle(isOn: Binding(
                                    get: { profile.notificationsEnabled },
                                    set: {
                                        profile.notificationsEnabled = $0
                                        try? modelContext.save()
                                        if $0 { updateNotifications(profile) }
                                        else { NotificationService.shared.cancelAll() }
                                    }
                                )) {
                                    HStack {
                                        Image(systemName: "bell.badge.fill")
                                            .foregroundStyle(SLTheme.Colors.primary)
                                        Text("Bedtime Reminders")
                                            .font(SLTheme.Typography.body)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .tint(SLTheme.Colors.primary)

                                if profile.notificationsEnabled {
                                    HStack {
                                        Text("Remind me")
                                            .font(SLTheme.Typography.subheadline)
                                            .foregroundStyle(SLTheme.Colors.textSecondary)

                                        Picker("Minutes", selection: Binding(
                                            get: { profile.reminderMinutesBefore },
                                            set: {
                                                profile.reminderMinutesBefore = $0
                                                try? modelContext.save()
                                                updateNotifications(profile)
                                            }
                                        )) {
                                            Text("15 min").tag(15)
                                            Text("30 min").tag(30)
                                            Text("45 min").tag(45)
                                            Text("60 min").tag(60)
                                        }
                                        .pickerStyle(.menu)
                                        .tint(SLTheme.Colors.primary)

                                        Text("before bedtime")
                                            .font(SLTheme.Typography.subheadline)
                                            .foregroundStyle(SLTheme.Colors.textSecondary)
                                    }
                                }
                            }
                        }
                    }

                    // About / Links
                    SLCard {
                        VStack(alignment: .leading, spacing: SLTheme.Spacing.md) {
                            Label("About", systemImage: "info.circle.fill")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(.white)

                            SettingsLinkRow(icon: "star.fill", title: "Rate SleepLock", color: SLTheme.Colors.accent)
                            SettingsLinkRow(icon: "square.and.arrow.up", title: "Share with Friends", color: SLTheme.Colors.secondary)
                            SettingsLinkRow(icon: "doc.text.fill", title: "Privacy Policy", color: SLTheme.Colors.textSecondary)
                            SettingsLinkRow(icon: "doc.plaintext.fill", title: "Terms of Service", color: SLTheme.Colors.textSecondary)
                        }
                    }

                    // Danger Zone
                    Button { showResetAlert = true } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(SLTheme.Colors.warning)
                            Text("Reset All Data")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(SLTheme.Colors.warning)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SLTheme.Spacing.md)
                        .background(SLTheme.Colors.warning.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                    }

                    Text("SleepLock v1.0.0\nAll data stored locally on your device")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, SLTheme.Spacing.huge)
                }
                .padding(.horizontal, SLTheme.Spacing.md)
            }
            .background(SLTheme.Colors.backgroundPrimary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SLTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetData() }
            } message: {
                Text("This will delete all your sleep logs, streaks, and settings. This cannot be undone.")
            }
        }
    }

    private func updateNotifications(_ profile: UserProfile) {
        NotificationService.shared.scheduleBedtimeReminder(
            bedtime: profile.targetBedtime,
            minutesBefore: profile.reminderMinutesBefore,
            userName: profile.displayName
        )
        NotificationService.shared.scheduleMorningLog(
            wakeTime: profile.targetWakeTime,
            userName: profile.displayName
        )
    }

    private func resetData() {
        try? modelContext.delete(model: SleepLogEntry.self)
        try? modelContext.delete(model: RoutineStep.self)
        try? modelContext.delete(model: UserProfile.self)
        NotificationService.shared.cancelAll()
    }
}

// MARK: - Settings Time Row
private struct SettingsTimeRow: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var time: Date

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(SLTheme.Typography.body)
                .foregroundStyle(.white)

            Spacer()

            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.dark)
        }
    }
}

// MARK: - Settings Link Row
private struct SettingsLinkRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button {} label: {
            HStack(spacing: SLTheme.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(SLTheme.Typography.body)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(SLTheme.Colors.textTertiary)
            }
        }
    }
}
