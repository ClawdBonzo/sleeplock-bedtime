import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var showResetAlert = false
    @State private var showPaywall = false
    @State private var isConnectingHealth = false
    @State private var healthStatus: String?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: SLTheme.Spacing.lg) {
                    // Profile section
                    if let profile {
                        SLCard {
                            HStack(spacing: SLTheme.Spacing.md) {
                                Image("BrandIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .shadow(color: SLTheme.Colors.primary.opacity(0.3), radius: 8)

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

                    // Upgrade to Premium
                    if !PurchaseService.shared.isPremium {
                        Button { showPaywall = true } label: {
                            HStack(spacing: SLTheme.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Premium")
                                        .font(SLTheme.Typography.headline)
                                        .foregroundStyle(.white)
                                    Text("Unlock all features & remove limits")
                                        .font(SLTheme.Typography.caption)
                                        .foregroundStyle(SLTheme.Colors.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(hex: "F59E0B"))
                            }
                            .padding(SLTheme.Spacing.md)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "F59E0B").opacity(0.15), Color(hex: "7C3AED").opacity(0.15)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
                            .overlay(
                                RoundedRectangle(cornerRadius: SLTheme.Radius.xl)
                                    .stroke(Color(hex: "F59E0B").opacity(0.4), lineWidth: 1)
                            )
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
                                            refreshWidgetBedtime(profile)
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

                    // Apple Health — clearly identifies HealthKit functionality (Guideline 2.5.1)
                    if HealthKitService.shared.isAvailable {
                        SLCard {
                            VStack(alignment: .leading, spacing: SLTheme.Spacing.md) {
                                Label("Apple Health", systemImage: "heart.fill")
                                    .font(SLTheme.Typography.headline)
                                    .foregroundStyle(.white)

                                Text("SleepLock can read your sleep analysis from Apple Health to automatically fill in your nightly sleep log. SleepLock only reads this data and never writes to Apple Health.")
                                    .font(SLTheme.Typography.subheadline)
                                    .foregroundStyle(SLTheme.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button {
                                    Task { await connectHealth() }
                                } label: {
                                    HStack(spacing: SLTheme.Spacing.sm) {
                                        if isConnectingHealth {
                                            ProgressView().tint(.white)
                                        } else {
                                            Image(systemName: "heart.text.square.fill")
                                                .foregroundStyle(Color(hex: "FF2D55"))
                                        }
                                        Text(healthStatus ?? String(localized: "Connect Apple Health"))
                                            .font(SLTheme.Typography.body)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        if healthStatus == nil && !isConnectingHealth {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(SLTheme.Colors.textTertiary)
                                        }
                                    }
                                    .padding(.vertical, SLTheme.Spacing.xs)
                                }
                                .disabled(isConnectingHealth)
                            }
                        }
                    }

                    // About / Links
                    SLCard {
                        VStack(alignment: .leading, spacing: SLTheme.Spacing.md) {
                            Label("About", systemImage: "info.circle.fill")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(.white)

                            Button {
                                openURL(SLLegal.writeReview)
                            } label: {
                                SettingsRowLabel(icon: "star.fill", title: "Rate SleepLock", color: SLTheme.Colors.accent)
                            }

                            ShareLink(
                                item: SLLegal.appStore,
                                message: Text("I've been fixing my sleep with SleepLock — lock in your best sleep!")
                            ) {
                                SettingsRowLabel(icon: "square.and.arrow.up", title: "Share with Friends", color: SLTheme.Colors.secondary)
                            }
                            SettingsLinkRow(icon: "doc.text.fill", title: "Privacy Policy", color: SLTheme.Colors.textSecondary, url: SLLegal.privacy)
                            SettingsLinkRow(icon: "doc.plaintext.fill", title: "Terms of Service", color: SLTheme.Colors.textSecondary, url: SLLegal.terms)
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

                    VStack(spacing: SLTheme.Spacing.sm) {
                        Image("BrandIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .opacity(0.6)

                        Text("SleepLock v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1")\nYour sleep data is stored locally on your device")
                            .font(SLTheme.Typography.caption)
                            .foregroundStyle(SLTheme.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
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
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView(
                    userName: profile?.displayName ?? "",
                    onContinue: { showPaywall = false }
                )
            }
        }
    }

    @MainActor
    private func connectHealth() async {
        isConnectingHealth = true
        defer { isConnectingHealth = false }
        let ok = await HealthKitService.shared.requestAuthorization()
        if ok {
            if await HealthKitService.shared.fetchLastNightSleep() != nil {
                healthStatus = String(localized: "Connected — last night imported ✓")
            } else {
                healthStatus = String(localized: "Connected to Apple Health ✓")
            }
            HapticFeedbackEngine.shared.triggerLightTap()
        } else {
            healthStatus = String(localized: "Apple Health unavailable")
        }
    }

    /// Keeps the widget's bedtime current when it's changed here — otherwise it
    /// shows the old time until the Dashboard next appears.
    private func refreshWidgetBedtime(_ profile: UserProfile) {
        guard var snapshot = SharedSnapshot.load() else { return }
        snapshot.bedtime = profile.targetBedtime.shortTime
        SharedSnapshot.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func updateNotifications(_ profile: UserProfile) {
        NotificationService.shared.scheduleBedtimeReminder(
            bedtime: profile.targetBedtime,
            minutesBefore: profile.reminderMinutesBefore,
            userName: profile.displayName,
            enforceBedtime: PurchaseService.shared.isPremium
        )
        NotificationService.shared.scheduleMorningLog(
            wakeTime: profile.targetWakeTime,
            userName: profile.displayName
        )
        NotificationService.shared.scheduleStreakSaverReminder(
            userName: profile.displayName,
            bedtime: profile.targetBedtime
        )
    }

    private func resetData() {
        try? modelContext.delete(model: SleepLogEntry.self)
        try? modelContext.delete(model: RoutineStep.self)
        try? modelContext.delete(model: UserProfile.self)
        try? modelContext.delete(model: GamificationProfile.self)
        try? modelContext.delete(model: Quest.self)
        try? modelContext.delete(model: Badge.self)
        NotificationService.shared.cancelAll()
    }
}

// MARK: - Settings Time Row
private struct SettingsTimeRow: View {
    let label: LocalizedStringKey
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

// MARK: - Settings Row Label
/// Shared visual for tappable About rows (used by Button and ShareLink alike).
private struct SettingsRowLabel: View {
    let icon: String
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
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

// MARK: - Settings Link Row
private struct SettingsLinkRow: View {
    let icon: String
    let title: LocalizedStringKey
    let color: Color
    var url: URL? = nil

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url { openURL(url) }
        } label: {
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
