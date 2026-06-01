import SwiftUI
import SwiftData

struct RoutineBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RoutineStep.sortOrder) private var steps: [RoutineStep]
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var showAddStep = false
    @State private var editingStep: RoutineStep?

    private var profile: UserProfile? { profiles.first }

    private var totalMinutes: Int {
        steps.filter(\.isEnabled).reduce(0) { $0 + $1.durationMinutes }
    }

    private var routineStartTime: String {
        guard let bedtime = profile?.targetBedtime else { return "--:--" }
        let start = Calendar.current.date(byAdding: .minute, value: -totalMinutes, to: bedtime)!
        return start.shortTime
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: SLTheme.Spacing.lg) {
                    // Routine summary
                    SLGlowCard(glowColor: SLTheme.Colors.moonGlow) {
                        VStack(spacing: SLTheme.Spacing.sm) {
                            HStack {
                                VStack(alignment: .leading, spacing: SLTheme.Spacing.xxs) {
                                    Text("Your Wind-Down Routine")
                                        .font(SLTheme.Typography.headline)
                                        .foregroundStyle(.white)

                                    Text("Start at \(routineStartTime) to be in bed by \(profile?.targetBedtime.shortTime ?? "--:--")")
                                        .font(SLTheme.Typography.caption)
                                        .foregroundStyle(SLTheme.Colors.textSecondary)
                                }

                                Spacer()

                                VStack {
                                    Text("\(totalMinutes)")
                                        .font(SLTheme.Typography.title)
                                        .foregroundStyle(SLTheme.Colors.moonGlow)
                                    Text("min")
                                        .font(SLTheme.Typography.caption)
                                        .foregroundStyle(SLTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }

                    // Steps timeline
                    VStack(spacing: 0) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            RoutineStepRow(
                                step: step,
                                isFirst: index == 0,
                                isLast: index == steps.count - 1,
                                onToggle: {
                                    withAnimation {
                                        step.isEnabled.toggle()
                                        try? modelContext.save()
                                    }
                                },
                                onEdit: {
                                    editingStep = step
                                },
                                onDelete: {
                                    modelContext.delete(step)
                                    try? modelContext.save()
                                    reorderSteps()
                                }
                            )
                        }
                    }

                    // Add step button
                    Button { showAddStep = true } label: {
                        HStack(spacing: SLTheme.Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                            Text("Add Step")
                                .font(SLTheme.Typography.headline)
                        }
                        .foregroundStyle(SLTheme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SLTheme.Spacing.md)
                        .background(SLTheme.Colors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                                .stroke(SLTheme.Colors.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )
                    }

                    // Tips
                    SLCard {
                        VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                            Label("Sleep Tips", systemImage: "lightbulb.fill")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(SLTheme.Colors.accent)

                            VStack(alignment: .leading, spacing: SLTheme.Spacing.xs) {
                                TipRow(text: "Start your routine at the same time each night")
                                TipRow(text: "Avoid screens 30+ minutes before bed")
                                TipRow(text: "Keep your bedroom cool and dark")
                                TipRow(text: "No caffeine after 2 PM")
                            }
                        }
                    }
                }
                .padding(.horizontal, SLTheme.Spacing.md)
                .padding(.bottom, SLTheme.Spacing.huge)
            }
            .background(SLTheme.Colors.backgroundPrimary)
            .navigationTitle("Sleep Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SLTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddStep) {
                AddStepSheet { title, icon, duration, category in
                    let step = RoutineStep(
                        title: title,
                        icon: icon,
                        durationMinutes: duration,
                        sortOrder: steps.count,
                        category: category
                    )
                    modelContext.insert(step)
                    try? modelContext.save()
                }
            }
            .sheet(item: $editingStep) { step in
                EditStepSheet(step: step) {
                    try? modelContext.save()
                }
            }
        }
    }

    private func reorderSteps() {
        for (index, step) in steps.enumerated() {
            step.sortOrder = index
        }
        try? modelContext.save()
    }
}

// MARK: - Routine Step Row
private struct RoutineStepRow: View {
    let step: RoutineStep
    let isFirst: Bool
    let isLast: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: SLTheme.Spacing.md) {
            // Timeline
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : SLTheme.Colors.primary.opacity(0.3))
                    .frame(width: 2)

                Circle()
                    .fill(step.isEnabled ? SLTheme.Colors.primary : SLTheme.Colors.textTertiary)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(step.isEnabled ? SLTheme.Colors.primary.opacity(0.3) : Color.clear)
                            .frame(width: 20, height: 20)
                    )

                Rectangle()
                    .fill(isLast ? Color.clear : SLTheme.Colors.primary.opacity(0.3))
                    .frame(width: 2)
            }
            .frame(width: 20)

            // Content
            HStack(spacing: SLTheme.Spacing.sm) {
                Image(systemName: step.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(step.isEnabled ? SLTheme.Colors.primaryLight : SLTheme.Colors.textTertiary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: SLTheme.Spacing.xxxs) {
                    Text(step.title)
                        .font(SLTheme.Typography.headline)
                        .foregroundStyle(step.isEnabled ? .white : SLTheme.Colors.textTertiary)
                        .strikethrough(!step.isEnabled, color: SLTheme.Colors.textTertiary)

                    Text("\(step.durationMinutes) min")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                }

                Spacer()

                Menu {
                    Button("Edit", systemImage: "pencil") { onEdit() }
                    Button(step.isEnabled ? "Disable" : "Enable", systemImage: step.isEnabled ? "eye.slash" : "eye") { onToggle() }
                    Button("Delete", systemImage: "trash", role: .destructive) { onDelete() }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.vertical, SLTheme.Spacing.sm)
            .padding(.horizontal, SLTheme.Spacing.md)
            .background(SLTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.md))
        }
        .frame(minHeight: 64)
    }
}

// MARK: - Tip Row
private struct TipRow: View {
    let text: LocalizedStringKey
    var body: some View {
        HStack(alignment: .top, spacing: SLTheme.Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(SLTheme.Colors.success)
            Text(text)
                .font(SLTheme.Typography.subheadline)
                .foregroundStyle(SLTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Add Step Sheet
private struct AddStepSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var icon = "moon"
    @State private var duration = 10
    @State private var category = "wind-down"

    let onSave: (String, String, Int, String) -> Void

    private let icons = ["moon", "book.fill", "figure.yoga", "wind", "drop.fill", "cup.and.saucer", "headphones", "pencil.and.list.clipboard", "heart.fill", "alarm.fill", "lightbulb.min", "iphone.slash"]

    var body: some View {
        NavigationStack {
            ZStack {
                SLTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SLTheme.Spacing.lg) {
                        TextField("Step name", text: $title)
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(.white)
                            .padding(SLTheme.Spacing.md)
                            .background(SLTheme.Colors.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))

                        VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                            Text("Icon")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(.white)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: SLTheme.Spacing.sm) {
                                ForEach(icons, id: \.self) { ic in
                                    Button {
                                        icon = ic
                                    } label: {
                                        Image(systemName: ic)
                                            .font(.system(size: 22))
                                            .foregroundStyle(icon == ic ? .white : SLTheme.Colors.textTertiary)
                                            .frame(width: 44, height: 44)
                                            .background(icon == ic ? SLTheme.Colors.primary : SLTheme.Colors.backgroundTertiary)
                                            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.sm))
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                            Text("Duration: \(duration) min")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(.white)

                            Slider(value: .init(get: { Double(duration) }, set: { duration = Int($0) }), in: 1...60, step: 1)
                                .tint(SLTheme.Colors.primary)
                        }

                        SLPrimaryButton("Add Step", icon: "plus") {
                            guard !title.isEmpty else { return }
                            onSave(title, icon, duration, category)
                            dismiss()
                        }
                    }
                    .padding(SLTheme.Spacing.xl)
                }
            }
            .navigationTitle("Add Step")
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
}

// MARK: - Edit Step Sheet
private struct EditStepSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var step: RoutineStep
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                SLTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SLTheme.Spacing.lg) {
                        TextField("Step name", text: $step.title)
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(.white)
                            .padding(SLTheme.Spacing.md)
                            .background(SLTheme.Colors.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))

                        VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                            Text("Duration: \(step.durationMinutes) min")
                                .font(SLTheme.Typography.headline)
                                .foregroundStyle(.white)

                            Slider(
                                value: .init(
                                    get: { Double(step.durationMinutes) },
                                    set: { step.durationMinutes = Int($0) }
                                ),
                                in: 1...60,
                                step: 1
                            )
                            .tint(SLTheme.Colors.primary)
                        }

                        SLPrimaryButton("Save Changes", icon: "checkmark") {
                            onSave()
                            dismiss()
                        }
                    }
                    .padding(SLTheme.Spacing.xl)
                }
            }
            .navigationTitle("Edit Step")
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
}
