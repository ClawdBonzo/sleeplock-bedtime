import SwiftUI

struct PaywallView: View {
    let userName: String
    let onContinue: () -> Void
    let onRestore: () -> Void

    @State private var selectedPlan = 1 // 0=weekly, 1=annual (highlighted), 2=monthly
    @Environment(\.dismiss) private var dismiss

    private let plans: [(title: String, price: String, perWeek: String, badge: String?, savings: String?)] = [
        ("Weekly", "$4.99/wk", "$4.99", nil, nil),
        ("Annual", "$39.99/yr", "$0.77", "BEST VALUE", "Save 85%"),
        ("Monthly", "$9.99/mo", "$2.50", nil, "Save 50%")
    ]

    var body: some View {
        ZStack {
            SLTheme.Colors.backgroundPrimary.ignoresSafeArea()
            StarsBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: SLTheme.Spacing.xl) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: onContinue) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(SLTheme.Colors.textTertiary)
                        }
                    }
                    .padding(.top, SLTheme.Spacing.sm)

                    // Before/After Energy Teaser
                    VStack(spacing: SLTheme.Spacing.md) {
                        Text("Unlock Your Best Energy")
                            .font(SLTheme.Typography.title)
                            .foregroundStyle(.white)

                        // Before/After comparison
                        HStack(spacing: SLTheme.Spacing.md) {
                            EnergyComparisonCard(
                                title: "Before",
                                emoji: "😴",
                                items: ["Inconsistent bedtime", "Low energy mornings", "Brain fog all day"],
                                color: SLTheme.Colors.warning
                            )

                            EnergyComparisonCard(
                                title: "After",
                                emoji: "⚡",
                                items: ["Locked-in routine", "Energized mornings", "Peak mental clarity"],
                                color: SLTheme.Colors.energyGreen
                            )
                        }
                    }

                    // Features
                    VStack(alignment: .leading, spacing: SLTheme.Spacing.sm) {
                        FeatureRow(icon: "flame.fill", text: "Unlimited streak tracking", color: SLTheme.Colors.streakGold)
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced sleep analytics", color: SLTheme.Colors.sleepBlue)
                        FeatureRow(icon: "bell.badge.fill", text: "Smart bedtime enforcement", color: SLTheme.Colors.primary)
                        FeatureRow(icon: "list.bullet.clipboard.fill", text: "Personalized routines", color: SLTheme.Colors.secondary)
                        FeatureRow(icon: "widget.medium.badge.plus", text: "Home screen widgets", color: SLTheme.Colors.accent)
                    }
                    .padding(SLTheme.Spacing.md)
                    .background(SLTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))

                    // Trial banner
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(SLTheme.Colors.accent)
                        Text("Start with a 3-day FREE trial")
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SLTheme.Spacing.md)
                    .background(SLTheme.Colors.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                            .stroke(SLTheme.Colors.accent.opacity(0.3), lineWidth: 1)
                    )

                    // Plan selection
                    VStack(spacing: SLTheme.Spacing.sm) {
                        ForEach(0..<plans.count, id: \.self) { index in
                            PlanRow(
                                plan: plans[index],
                                isSelected: selectedPlan == index,
                                onTap: { selectedPlan = index }
                            )
                        }
                    }

                    // CTA
                    VStack(spacing: SLTheme.Spacing.sm) {
                        SLPrimaryButton("Start Free Trial") {
                            // RevenueCat purchase will go here
                            onContinue()
                        }

                        Text("Cancel anytime. No charge for 3 days.")
                            .font(SLTheme.Typography.caption)
                            .foregroundStyle(SLTheme.Colors.textTertiary)

                        HStack(spacing: SLTheme.Spacing.xl) {
                            Button("Restore Purchases") { onRestore() }
                            Button("Terms") {}
                            Button("Privacy") {}
                        }
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                    }
                    .padding(.bottom, SLTheme.Spacing.xxl)
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
            }
        }
    }
}

// MARK: - Energy Comparison Card
private struct EnergyComparisonCard: View {
    let title: String
    let emoji: String
    let items: [String]
    let color: Color

    var body: some View {
        VStack(spacing: SLTheme.Spacing.sm) {
            Text(emoji)
                .font(.system(size: 36))

            Text(title)
                .font(SLTheme.Typography.headline)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: SLTheme.Spacing.xxs) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: SLTheme.Spacing.xxs) {
                        Image(systemName: title == "Before" ? "xmark" : "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(color)
                        Text(item)
                            .font(SLTheme.Typography.caption)
                            .foregroundStyle(SLTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(SLTheme.Spacing.md)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
    }
}

// MARK: - Feature Row
private struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: SLTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 28)

            Text(text)
                .font(SLTheme.Typography.body)
                .foregroundStyle(.white)

            Spacer()
        }
    }
}

// MARK: - Plan Row
private struct PlanRow: View {
    let plan: (title: String, price: String, perWeek: String, badge: String?, savings: String?)
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: SLTheme.Spacing.xxxs) {
                    HStack(spacing: SLTheme.Spacing.xs) {
                        Text(plan.title)
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(.white)

                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(SLTheme.Colors.accent)
                                .clipShape(Capsule())
                        }
                    }

                    Text(plan.price)
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: SLTheme.Spacing.xxxs) {
                    Text("\(plan.perWeek)/wk")
                        .font(SLTheme.Typography.callout)
                        .foregroundStyle(.white)

                    if let savings = plan.savings {
                        Text(savings)
                            .font(SLTheme.Typography.caption)
                            .foregroundStyle(SLTheme.Colors.energyGreen)
                    }
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? SLTheme.Colors.primary : SLTheme.Colors.textTertiary)
                    .padding(.leading, SLTheme.Spacing.xs)
            }
            .padding(SLTheme.Spacing.md)
            .background(isSelected ? SLTheme.Colors.primary.opacity(0.12) : SLTheme.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .stroke(isSelected ? SLTheme.Colors.primary : Color.clear, lineWidth: 1.5)
            )
        }
    }
}
