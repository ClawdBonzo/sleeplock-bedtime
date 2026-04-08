import SwiftUI
import RevenueCat

struct PaywallView: View {
    let userName: String
    let onContinue: () -> Void
    let onRestore: () -> Void

    @State private var selectedIndex = 1 // 0=weekly, 1=monthly (BEST VALUE), 2=yearly, 3=lifetime
    @State private var packages: [Package] = []
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    // Display order: Weekly, Monthly (BEST VALUE), Yearly, Lifetime
    private let planMeta: [(key: String, badge: String?, savings: String?)] = [
        ("$rc_weekly",   nil,          nil),
        ("$rc_monthly",  "BEST VALUE", nil),
        ("$rc_annual",   nil,          "Save 58%"),
        ("$rc_lifetime", nil,          "Best Deal")
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

                    // Paywall hero illustration
                    Image("Onboarding-5")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.xl))
                        .shadow(color: SLTheme.Colors.primary.opacity(0.3), radius: 16, y: 6)

                    // Before/After Energy Teaser
                    VStack(spacing: SLTheme.Spacing.md) {
                        Text("Unlock Your Best Energy")
                            .font(SLTheme.Typography.title)
                            .foregroundStyle(.white)

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

                    // Plan selection — live from RevenueCat
                    VStack(spacing: SLTheme.Spacing.sm) {
                        if packages.isEmpty {
                            // Fallback while loading
                            ProgressView()
                                .tint(SLTheme.Colors.primary)
                                .frame(height: 60)
                        } else {
                            ForEach(Array(packages.enumerated()), id: \.element.id) { index, pkg in
                                let meta = index < planMeta.count ? planMeta[index] : (key: "", badge: nil as String?, savings: nil as String?)
                                LivePlanRow(
                                    package: pkg,
                                    badge: meta.badge,
                                    savings: meta.savings,
                                    isSelected: selectedIndex == index,
                                    onTap: { selectedIndex = index }
                                )
                            }
                        }
                    }

                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(SLTheme.Typography.caption)
                            .foregroundStyle(SLTheme.Colors.warning)
                    }

                    // CTA
                    VStack(spacing: SLTheme.Spacing.sm) {
                        Button {
                            Task { await purchaseSelected() }
                        } label: {
                            HStack(spacing: SLTheme.Spacing.sm) {
                                if isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                Text(isPurchasing ? "Processing..." : "Start Free Trial")
                                    .font(SLTheme.Typography.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(SLTheme.Colors.gradientPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                            .shadow(color: SLTheme.Colors.primary.opacity(0.4), radius: 12, y: 4)
                        }
                        .disabled(isPurchasing || packages.isEmpty)
                        .opacity(isPurchasing ? 0.7 : 1)

                        Text("Cancel anytime. No charge for 3 days.")
                            .font(SLTheme.Typography.caption)
                            .foregroundStyle(SLTheme.Colors.textTertiary)

                        HStack(spacing: SLTheme.Spacing.xl) {
                            Button("Restore Purchases") {
                                Task { await restorePurchases() }
                            }
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
        .task {
            await loadOfferings()
        }
    }

    // MARK: - Load Offerings
    private func loadOfferings() async {
        await PurchaseService.shared.fetchOfferings()
        guard let offering = PurchaseService.shared.offerings?.current else { return }

        // Order: weekly, monthly, annual, lifetime
        let orderedKeys = ["$rc_weekly", "$rc_monthly", "$rc_annual", "$rc_lifetime"]
        var ordered: [Package] = []
        for key in orderedKeys {
            if let pkg = offering.package(identifier: key) {
                ordered.append(pkg)
            }
        }
        packages = ordered
    }

    // MARK: - Purchase
    private func purchaseSelected() async {
        guard selectedIndex < packages.count else { return }
        isPurchasing = true
        errorMessage = nil

        let success = await PurchaseService.shared.purchase(package: packages[selectedIndex])

        isPurchasing = false
        if success {
            onContinue()
        }
    }

    // MARK: - Restore
    private func restorePurchases() async {
        isPurchasing = true
        errorMessage = nil

        let restored = await PurchaseService.shared.restore()

        isPurchasing = false
        if restored {
            onContinue()
        } else {
            errorMessage = "No active subscription found."
        }
    }
}

// MARK: - Live Plan Row (RevenueCat Package)
private struct LivePlanRow: View {
    let package: Package
    let badge: String?
    let savings: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: SLTheme.Spacing.xxxs) {
                    HStack(spacing: SLTheme.Spacing.xs) {
                        Text(package.storeProduct.localizedTitle)
                            .font(SLTheme.Typography.headline)
                            .foregroundStyle(.white)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(SLTheme.Colors.accent)
                                .clipShape(Capsule())
                        }
                    }

                    Text(package.localizedPriceString + periodLabel)
                        .font(SLTheme.Typography.subheadline)
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: SLTheme.Spacing.xxxs) {
                    if let savings {
                        Text(savings)
                            .font(SLTheme.Typography.caption)
                            .foregroundStyle(SLTheme.Colors.energyGreen)
                    }

                    if let intro = package.storeProduct.introductoryDiscount,
                       intro.price == 0 {
                        Text("\(intro.subscriptionPeriod.value)-day free trial")
                            .font(.system(size: 10))
                            .foregroundStyle(SLTheme.Colors.accent)
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

    private var periodLabel: String {
        switch package.packageType {
        case .weekly:   return "/wk"
        case .monthly:  return "/mo"
        case .annual:   return "/yr"
        case .lifetime: return ""
        default:        return ""
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
