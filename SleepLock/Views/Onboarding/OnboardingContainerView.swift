import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var profile = OnboardingProfile()

    let onComplete: () -> Void

    private let totalSteps = 6

    var body: some View {
        ZStack {
            SLTheme.Colors.backgroundPrimary.ignoresSafeArea()
            StarsBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                if currentStep > 0 && currentStep < 6 {
                    OnboardingProgressBar(current: currentStep, total: totalSteps)
                        .padding(.horizontal, SLTheme.Spacing.xl)
                        .padding(.top, SLTheme.Spacing.sm)
                }

                // Deliberately not a paging TabView: swiping would bypass each
                // step's validation (empty name, etc.), and page-style TabViews
                // pre-load neighbors — starting CraftingRoutineScreen's timers
                // and the splash's repeat-forever animations early. Only one
                // screen exists at a time; `advanceStep` is the only way forward.
                ZStack {
                    switch currentStep {
                    case 0:
                        SplashScreen(onStart: advanceStep)
                    case 1:
                        NameEntryScreen(name: $profile.name, onNext: advanceStep)
                    case 2:
                        SleepHabitsScreen(selectedHabit: $profile.sleepHabit, onNext: advanceStep)
                    case 3:
                        BedtimePickerScreen(
                            bedtime: $profile.bedtime,
                            wakeTime: $profile.wakeTime,
                            onNext: advanceStep
                        )
                    case 4:
                        BlockersScreen(selectedBlockers: $profile.blockers, onNext: advanceStep)
                    default:
                        CraftingRoutineScreen(
                            name: profile.name,
                            onComplete: {
                                saveProfile()
                                onComplete()
                            }
                        )
                    }
                }
                .id(currentStep)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.4), value: currentStep)
            }
        }
        .onChange(of: currentStep) { _, _ in
            // Dismiss any stuck keyboard (e.g. from NameEntryScreen) when advancing.
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }

    private func advanceStep() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep += 1
        }
    }

    private func saveProfile() {
        let userProfile = UserProfile(
            displayName: profile.name,
            targetBedtime: profile.bedtime,
            targetWakeTime: profile.wakeTime,
            sleepBlockers: profile.blockers,
            currentSleepHabit: profile.sleepHabit,
            onboardingCompleted: true
        )
        modelContext.insert(userProfile)

        // Create default routine steps
        for (index, template) in RoutineTemplate.defaults.enumerated() {
            let step = RoutineStep(
                title: template.title,
                icon: template.icon,
                durationMinutes: template.duration,
                sortOrder: index,
                isEnabled: true,
                category: template.category
            )
            modelContext.insert(step)
        }

        try? modelContext.save()

        // Schedule notifications
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                NotificationService.shared.scheduleBedtimeReminder(
                    bedtime: profile.bedtime,
                    minutesBefore: 30,
                    userName: profile.name,
                    enforceBedtime: PurchaseService.shared.isPremium
                )
                NotificationService.shared.scheduleMorningLog(
                    wakeTime: profile.wakeTime,
                    userName: profile.name
                )
                NotificationService.shared.scheduleStreakSaverReminder(
                    userName: profile.name
                )
            }
        }
    }
}

// MARK: - Onboarding Profile (transient)
struct OnboardingProfile {
    var name: String = ""
    var sleepHabit: String = ""
    var bedtime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
    var wakeTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    var blockers: [String] = []
}

// MARK: - Progress Bar
struct OnboardingProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: SLTheme.Spacing.xxs) {
            ForEach(1...total, id: \.self) { step in
                Capsule()
                    .fill(step <= current ? SLTheme.Colors.primary : SLTheme.Colors.backgroundTertiary)
                    .frame(height: 4)
            }
        }
    }
}
