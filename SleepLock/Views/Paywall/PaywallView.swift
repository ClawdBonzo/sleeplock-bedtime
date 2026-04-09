import SwiftUI
import RevenueCat

struct PaywallView: View {
    let userName: String
    let onContinue: () -> Void
    let onRestore: () -> Void

    @State private var selectedIndex = 1 // 0=monthly (BEST VALUE), 1=yearly
    @State private var packages: [Package] = []
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var heroScale: CGFloat = 0.7
    @State private var heroOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var plansOffset: CGFloat = 30
    @Environment(\.dismiss) private var dismiss

    private let planMeta: [(key: String, badge: String?, savings: String?)] = [
        ("$rc_monthly",  "BEST VALUE", nil),
        ("$rc_annual",   nil,          "Save 58%"),
    ]

    // Fallback plan data shown immediately while RevenueCat loads
    private let fallbackPlans: [(title: String, price: String, period: String, badge: String?, savings: String?, hasTrial: Bool)] = [
        ("Monthly",  "$4.99",  "/mo", "BEST VALUE", nil,       true),
        ("Annual",   "$29.99", "/yr", nil,          "Save 58%", true),
    ]

    var body: some View {
        ZStack {
            SLTheme.Colors.backgroundPrimary.ignoresSafeArea()
            StarsBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                // Close
                HStack {
                    Spacer()
                    Button(action: onContinue) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(SLTheme.Colors.textTertiary)
                    }
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .padding(.top, SLTheme.Spacing.sm)

                // Hero
                VStack(spacing: SLTheme.Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(SLTheme.Colors.primary.opacity(0.15))
                            .frame(width: 96, height: 96)
                            .blur(radius: 12)

                        Image("BrandIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: SLTheme.Colors.primary.opacity(0.5), radius: 16)
                    }
                    .scaleEffect(heroScale)
                    .opacity(heroOpacity)

                    VStack(spacing: 4) {
                        Text("Unlock Your Best Energy")
                            .font(SLTheme.Typography.title)
                            .foregroundStyle(.white)

                        Text("Build habits that last a lifetime")
                            .font(SLTheme.Typography.subheadline)
                            .foregroundStyle(SLTheme.Colors.textSecondary)
                    }
                    .opacity(contentOpacity)
                }
                .padding(.top, SLTheme.Spacing.sm)

                Spacer(minLength: 0)

                // Features (compact 3-row)
                VStack(alignment: .leading, spacing: SLTheme.Spacing.xs) {
                    CompactFeatureRow(icon: "flame.fill",              text: "Unlimited streak tracking",    color: SLTheme.Colors.streakGold)
                    CompactFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced sleep analytics",  color: SLTheme.Colors.sleepBlue)
                    CompactFeatureRow(icon: "bell.badge.fill",         text: "Smart bedtime enforcement",   color: SLTheme.Colors.primary)
                    CompactFeatureRow(icon: "star.fill",               text: "Full gamification + XP",      color: SLTheme.Colors.accent)
                    CompactFeatureRow(icon: "widget.medium.badge.plus", text: "Home screen widgets",        color: SLTheme.Colors.secondary)
                }
                .padding(SLTheme.Spacing.md)
                .background(SLTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                .padding(.horizontal, SLTheme.Spacing.xl)
                .opacity(contentOpacity)

                Spacer(minLength: 0)

                // Trial badge
                HStack(spacing: SLTheme.Spacing.xs) {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(SLTheme.Colors.accent)
                        .font(.system(size: 15))
                    Text("Start with a FREE 3-day trial")
                        .font(SLTheme.Typography.headline)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SLTheme.Spacing.sm)
                .background(SLTheme.Colors.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.md))
                .overlay(RoundedRectangle(cornerRadius: SLTheme.Radius.md)
                    .stroke(SLTheme.Colors.accent.opacity(0.25), lineWidth: 1))
                .padding(.horizontal, SLTheme.Spacing.xl)
                .opacity(contentOpacity)

                Spacer(minLength: SLTheme.Spacing.sm)

                // Plans — show live RevenueCat rows when loaded, fallback otherwise
                VStack(spacing: SLTheme.Spacing.sm) {
                    if packages.isEmpty {
                        ForEach(Array(fallbackPlans.enumerated()), id: \.offset) { index, plan in
                            FallbackPlanRow(
                                title: plan.title,
                                price: plan.price,
                                period: plan.period,
                                badge: plan.badge,
                                savings: plan.savings,
                                hasTrial: plan.hasTrial,
                                isSelected: selectedIndex == index,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedIndex = index
                                    }
                                    HapticFeedbackEngine.shared.triggerLightTap()
                                }
                            )
                        }
                    } else {
                        let displayPackages = packages.prefix(2)
                        ForEach(Array(displayPackages.enumerated()), id: \.element.id) { index, pkg in
                            let meta = index < planMeta.count ? planMeta[index] : (key: "", badge: nil as String?, savings: nil as String?)
                            LivePlanRow(
                                package: pkg,
                                badge: meta.badge,
                                savings: meta.savings,
                                isSelected: selectedIndex == index,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedIndex = index
                                    }
                                    HapticFeedbackEngine.shared.triggerLightTap()
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .offset(y: plansOffset)
                .opacity(contentOpacity)

                // Error
                if let errorMessage {
                    Text(errorMessage)
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.warning)
                        .padding(.horizontal, SLTheme.Spacing.xl)
                }

                Spacer(minLength: SLTheme.Spacing.sm)

                // CTA + legal (pinned to bottom)
                VStack(spacing: SLTheme.Spacing.xs) {
                    Button {
                        Task { await purchaseSelected() }
                    } label: {
                        HStack(spacing: SLTheme.Spacing.sm) {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "sparkles").font(.system(size: 18, weight: .semibold))
                            }
                            Text(isPurchasing ? "Processing..." : "Start Free Trial")
                                .font(SLTheme.Typography.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isPurchasing ? AnyShapeStyle(SLTheme.Colors.backgroundTertiary) : AnyShapeStyle(SLTheme.Colors.gradientPrimary))
                        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                        .shadow(color: SLTheme.Colors.primary.opacity(0.4), radius: 12, y: 4)
                    }
                    .disabled(isPurchasing)

                    Text("Cancel anytime. No charge for 3 days.")
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.textTertiary)

                    HStack(spacing: SLTheme.Spacing.xl) {
                        Button("Restore") { Task { await restorePurchases() } }
                        Button("Terms") {}
                        Button("Privacy") {}
                    }
                    .font(SLTheme.Typography.caption)
                    .foregroundStyle(SLTheme.Colors.textTertiary)
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .padding(.bottom, SLTheme.Spacing.xl)
                .opacity(contentOpacity)
            }
        }
        .task { await loadOfferings() }
        .onAppear { runEntrance() }
    }

    // MARK: - Entrance Animation
    private func runEntrance() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
            heroScale = 1.0
            heroOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
            contentOpacity = 1
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4)) {
            plansOffset = 0
        }
    }

    // MARK: - Load
    private func loadOfferings() async {
        await PurchaseService.shared.fetchOfferings()
        guard let offering = PurchaseService.shared.offerings?.current else { return }

        let orderedKeys = ["$rc_monthly", "$rc_annual"]
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
        guard selectedIndex < packages.count else {
            // Packages not yet loaded from RevenueCat — skip to main app
            onContinue()
            return
        }
        isPurchasing = true
        errorMessage = nil
        let success = await PurchaseService.shared.purchase(package: packages[selectedIndex])
        isPurchasing = false
        if success { onContinue() }
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

// MARK: - Compact Feature Row
private struct CompactFeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: SLTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 22)

            Text(text)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color.opacity(0.7))
        }
    }
}

// MARK: - Fallback Plan Row (shown when RevenueCat sandbox has no packages)
private struct FallbackPlanRow: View {
    let title: String
    let price: String
    let period: String
    let badge: String?
    let savings: String?
    let hasTrial: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
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

                    Text(price + period)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(SLTheme.Colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let savings {
                        Text(savings)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SLTheme.Colors.energyGreen)
                    }

                    if hasTrial {
                        Text("3-day trial")
                            .font(.system(size: 10))
                            .foregroundStyle(SLTheme.Colors.accent)
                    }
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? SLTheme.Colors.primary : SLTheme.Colors.textTertiary)
                    .padding(.leading, 6)
            }
            .padding(SLTheme.Spacing.md)
            .background(isSelected ? SLTheme.Colors.primary.opacity(0.12) : SLTheme.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .stroke(isSelected ? SLTheme.Colors.primary : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Live Plan Row
private struct LivePlanRow: View {
    let package: Package
    let badge: String?
    let savings: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
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

                VStack(alignment: .trailing, spacing: 2) {
                    if let savings {
                        Text(savings)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SLTheme.Colors.energyGreen)
                    }

                    if let intro = package.storeProduct.introductoryDiscount, intro.price == 0 {
                        Text("\(intro.subscriptionPeriod.value)-day trial")
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

// MARK: - Shimmer modifier
private extension View {
    func shimmer() -> some View {
        self.overlay(
            LinearGradient(
                colors: [.clear, .white.opacity(0.08), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}
