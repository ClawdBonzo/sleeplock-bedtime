import SwiftUI
import SwiftData

struct DailyLoggerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(GamificationService.self) private var gamificationService
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var actualBedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
    @State private var actualWakeTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var energyRating: Int = 3
    @State private var notes: String = ""
    @State private var showSuccess = false
    @State private var isImportingHealth = false
    @State private var healthImportMessage: String?
    /// Today's already-saved entry, when the user is editing rather than logging.
    @State private var existingEntry: SleepLogEntry?
    @State private var didPrefill = false

    private var profile: UserProfile? { profiles.first }

    private var hitTarget: Bool {
        guard let profile else { return false }
        // Wrap-around clock math: post-midnight bedtimes are "later" than
        // evening ones, and an early bedtime always hits (15-min grace for late).
        return NightMath.hitsTarget(actualBedtime: actualBedtime, targetBedtime: profile.targetBedtime)
    }

    // Explicitly LocalizedStringKey: a bare ternary of string literals can
    // resolve to the non-localizing String overloads of Text/navigationTitle.
    private var navTitle: LocalizedStringKey {
        existingEntry == nil ? "Log Sleep" : "Update Sleep Log"
    }
    private var headerTitle: LocalizedStringKey {
        existingEntry == nil ? "Logging for last night" : "Editing today's log"
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

                if gamificationService.showLevelUpAnimation {
                    LevelUpAnimationView(level: gamificationService.lastLevelUpLevel ?? .nightOwl)
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }
            }
            .toolbarBackground(SLTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { prefillIfNeeded() }
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
                        Text(headerTitle)
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text(Date().monthDay)
                            .font(SLTheme.Typography.subheadline)
                            .foregroundStyle(SLTheme.Colors.textSecondary)
                    }
                }

                // Apple Health auto-import
                if HealthKitService.shared.isAvailable {
                    Button {
                        Task { await importFromHealth() }
                    } label: {
                        HStack(spacing: SLTheme.Spacing.sm) {
                            if isImportingHealth {
                                ProgressView().tint(SLTheme.Colors.primary)
                            } else {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(Color(hex: "FF2D55"))
                            }
                            Text(healthImportMessage ?? String(localized: "Import from Apple Health"))
                                .font(SLTheme.Typography.subheadline)
                                .foregroundStyle(.white)
                            Spacer()
                            if healthImportMessage == nil && !isImportingHealth {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(SLTheme.Colors.textTertiary)
                            }
                        }
                        .padding(SLTheme.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(SLTheme.Colors.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                    }
                    .disabled(isImportingHealth)
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
                            .clipped()
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
                            .clipped()
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
                                Button {
                                    withAnimation(SLTheme.Animation.bouncy) {
                                        energyRating = level.rawValue
                                    }
                                } label: {
                                    VStack(spacing: SLTheme.Spacing.xxs) {
                                        Image(systemName: level.emoji)
                                            .font(.system(size: energyRating == level.rawValue ? 32 : 24, weight: .semibold))
                                            .foregroundStyle(
                                                energyRating == level.rawValue ?
                                                level.color : SLTheme.Colors.textTertiary
                                            )
                                            .scaleEffect(energyRating == level.rawValue ? 1.1 : 1)

                                        Text(level.label)
                                            .font(.system(size: 9))
                                            .foregroundStyle(
                                                energyRating == level.rawValue ?
                                                level.color : SLTheme.Colors.textTertiary
                                            )
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(level.label)
                                .accessibilityAddTraits(energyRating == level.rawValue ? .isSelected : [])
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

                SLPrimaryButton(existingEntry == nil ? "Save Sleep Log" : "Update Sleep Log", icon: "checkmark") {
                    saveEntry()
                }
                .padding(.bottom, SLTheme.Spacing.xxl)
            }
            .padding(.horizontal, SLTheme.Spacing.md)
        }
    }

    // MARK: - Success View
    private var successView: some View {
        ZStack {
            if hitTarget && !reduceMotion {
                ConfettiBurst()
                    .allowsHitTesting(false)
            }
            successContent
        }
    }

    private var successContent: some View {
        VStack(spacing: SLTheme.Spacing.xxl) {
            Spacer()

            Image(systemName: hitTarget ? "flame.fill" : "moon.fill")
                .font(.system(size: 80))
                .foregroundStyle(hitTarget ? SLTheme.Colors.streakGold : SLTheme.Colors.primaryLight)
                .shadow(color: (hitTarget ? SLTheme.Colors.streakGold : SLTheme.Colors.primary).opacity(0.4), radius: 20)
                .scaleEffect(showSuccess ? 1 : 0.4)
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.5), value: showSuccess)

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

    // MARK: - Prefill

    /// Starts the pickers from the user's actual targets (most nights are a
    /// confirmation, not data entry) — or from today's entry when editing it.
    private func prefillIfNeeded() {
        guard !didPrefill else { return }
        didPrefill = true

        existingEntry = fetchTodayEntry()
        if let entry = existingEntry {
            actualBedtime = entry.actualBedtime
            actualWakeTime = entry.actualWakeTime
            energyRating = entry.morningEnergyRating
            notes = entry.notes
        } else if let profile {
            actualBedtime = profile.targetBedtime
            actualWakeTime = profile.targetWakeTime
        }
    }

    private func fetchTodayEntry() -> SleepLogEntry? {
        let start = Date().startOfDay
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        var descriptor = FetchDescriptor<SleepLogEntry>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    // MARK: - Save

    /// One entry per night: a second save today edits the existing log instead
    /// of inserting a duplicate, and XP/quests/badges award only on first log.
    private func saveEntry() {
        let isFirstLogOfNight = existingEntry == nil

        if let entry = existingEntry {
            entry.actualBedtime = actualBedtime
            entry.actualWakeTime = actualWakeTime
            entry.targetBedtime = profile?.targetBedtime ?? actualBedtime
            entry.morningEnergyRating = energyRating
            entry.notes = notes
            entry.hitTarget = hitTarget
            entry.recalculateDuration()
        } else {
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
            existingEntry = entry
        }
        try? modelContext.save()

        // Confirmation haptic
        HapticFeedbackEngine.shared.triggerLightTap()

        let streak = currentStreakIncludingFreezes()
        gamificationService.recordSleepLogged(
            hitTarget: hitTarget,
            energyRating: energyRating,
            isFirstLogOfNight: isFirstLogOfNight,
            currentStreak: streak
        )

        if isFirstLogOfNight && hitTarget {
            let milestones: Set<Int> = [7, 14, 30, 60, 100, 180, 365]
            if milestones.contains(streak) {
                HapticFeedbackEngine.shared.triggerStreakMilestone()
            }
        }

        // Re-arm the lapsed-user reminder relative to this fresh log — but only
        // when the user hasn't switched notifications off.
        if profile?.notificationsEnabled == true {
            NotificationService.shared.scheduleReengagementReminder(
                userName: profile?.displayName ?? "",
                currentStreak: streak
            )
        }

        withAnimation(SLTheme.Animation.spring) {
            showSuccess = true
        }
    }

    /// The same freeze-aware streak the dashboard shows — so badges, milestones,
    /// and notifications never disagree with the number on screen.
    private func currentStreakIncludingFreezes() -> Int {
        var descriptor = FetchDescriptor<SleepLogEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 730
        guard let entries = try? modelContext.fetch(descriptor) else { return 0 }
        let frozen = Set((try? modelContext.fetch(FetchDescriptor<GamificationProfile>()))?.first?.frozenDateKeys ?? [])
        return StreakCalculator.currentStreak(entries: entries, frozenKeys: frozen)
    }

    @MainActor
    private func importFromHealth() async {
        isImportingHealth = true
        defer { isImportingHealth = false }

        let authorized = await HealthKitService.shared.requestAuthorization()
        guard authorized else {
            healthImportMessage = String(localized: "Health access unavailable")
            return
        }

        if let sample = await HealthKitService.shared.fetchLastNightSleep() {
            actualBedtime = sample.bedtime
            actualWakeTime = sample.wakeTime
            healthImportMessage = String(localized: "Imported from Apple Health ✓")
            HapticFeedbackEngine.shared.triggerLightTap()
        } else {
            healthImportMessage = String(localized: "No sleep data found in Health")
        }
    }
}

// MARK: - Confetti

/// Lightweight one-shot confetti burst for celebratory moments. Pure SwiftUI,
/// GPU-animated, no timers — pieces fall and fade once on appear.
private struct ConfettiBurst: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let hue: Double
        let size: CGFloat
        let spin: Double
    }

    private let pieces: [Piece] = (0..<28).map { _ in
        Piece(
            x: CGFloat.random(in: 0.05...0.95),
            delay: Double.random(in: 0...0.35),
            hue: Double.random(in: 0...1),
            size: CGFloat.random(in: 6...11),
            spin: Double.random(in: -240...240)
        )
    }

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hue: piece.hue, saturation: 0.8, brightness: 1.0))
                        .frame(width: piece.size, height: piece.size * 1.6)
                        .position(
                            x: piece.x * geo.size.width,
                            y: animate ? geo.size.height + 40 : -40
                        )
                        .rotationEffect(.degrees(animate ? piece.spin : 0))
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeIn(duration: 1.6).delay(piece.delay),
                            value: animate
                        )
                }
            }
        }
        .onAppear { animate = true }
    }
}
