import SwiftUI
import RevenueCat

// MARK: - Plan Configuration

private struct PlanConfig: Identifiable {
    let id: String
    let rcKey: String
    let title: LocalizedStringKey
    let fallbackPrice: String
    let period: String           // "/wk", "/mo", "/yr", "" for lifetime
    let badge: LocalizedStringKey?
    let badgeIsGold: Bool
    let savings: LocalizedStringKey?
    let hasTrial: Bool
    let isLifetime: Bool
}

private nonisolated(unsafe) let allPlans: [PlanConfig] = [
    PlanConfig(
        id: "weekly",
        rcKey: "$rc_weekly",
        title: "Weekly",
        fallbackPrice: "$4.99",
        period: "/wk",
        badge: nil,
        badgeIsGold: false,
        savings: nil,
        hasTrial: false,
        isLifetime: false
    ),
    PlanConfig(
        id: "monthly",
        rcKey: "$rc_monthly",
        title: "Monthly",
        fallbackPrice: "$9.99",
        period: "/mo",
        badge: "BEST VALUE",
        badgeIsGold: true,
        savings: nil,
        hasTrial: true,
        isLifetime: false
    ),
    PlanConfig(
        id: "yearly",
        rcKey: "$rc_annual",
        title: "Yearly",
        fallbackPrice: "$49.99",
        period: "/yr",
        badge: nil,
        badgeIsGold: false,
        savings: "Save 58%",
        hasTrial: true,
        isLifetime: false
    ),
    PlanConfig(
        id: "lifetime",
        rcKey: "$rc_lifetime",
        title: "Lifetime",
        fallbackPrice: "$79.99",
        period: "",
        badge: "ONE TIME",
        badgeIsGold: false,
        savings: nil,
        hasTrial: false,
        isLifetime: true
    ),
]

// MARK: - PaywallView

struct PaywallView: View {
    let userName: String
    let onContinue: () -> Void
    let onRestore: () -> Void
    var allowDismiss: Bool = true

    @State private var selectedIndex = 1        // Monthly pre-selected
    @State private var rcPackages: [String: Package] = [:]
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var appeared = false
    @State private var showMaybeLater = false
    @Environment(\.dismiss) private var dismiss

    private var selectedPlan: PlanConfig { allPlans[selectedIndex] }

    private var ctaText: String {
        if isPurchasing { return String(localized: "Processing...") }
        if selectedPlan.hasTrial { return String(localized: "Start 3-Day Free Trial") }
        if selectedPlan.isLifetime { return String(localized: "Get Lifetime Access") }
        return String(localized: "Subscribe Now")
    }

    // Auto-renewable subscription disclosure (Apple Guideline 3.1.2).
    private var disclosureText: LocalizedStringKey {
        if selectedPlan.isLifetime {
            return "One-time purchase — no subscription, no auto-renewal."
        }
        if selectedPlan.hasTrial {
            return "3-day free trial, then auto-renews until canceled. Cancel anytime in Settings."
        }
        return "Auto-renews until canceled. Cancel anytime in Settings."
    }

    var body: some View {
        ZStack {
            SLTheme.Colors.backgroundPrimary.ignoresSafeArea()
            StarsBackground().ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Close button (only when dismissal is allowed) ─────
                HStack {
                    Spacer()
                    if allowDismiss {
                        Button(action: onContinue) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(SLTheme.Colors.textTertiary)
                        }
                    }
                }
                .frame(height: 36)
                .padding(.horizontal, SLTheme.Spacing.xl)
                .padding(.top, SLTheme.Spacing.sm)

                // ── Compact header ────────────────────────────────────
                HStack(spacing: SLTheme.Spacing.md) {
                    Image("BrandIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 62, height: 62)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: SLTheme.Colors.primary.opacity(0.6), radius: 14)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("SleepLock Pro")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Transform your sleep. Transform your life.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(SLTheme.Colors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer()
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .padding(.top, SLTheme.Spacing.sm)
                .padding(.bottom, SLTheme.Spacing.md)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -10)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

                // ── Feature list (glassmorphism) ──────────────────────
                VStack(spacing: 8) {
                    PaywallFeatureRow(icon: "flame.fill",                 text: "Unlimited streak tracking",  color: SLTheme.Colors.streakGold)
                    PaywallFeatureRow(icon: "chart.line.uptrend.xyaxis",  text: "Advanced sleep analytics",   color: SLTheme.Colors.sleepBlue)
                    PaywallFeatureRow(icon: "bell.badge.fill",            text: "Smart bedtime enforcement",  color: SLTheme.Colors.primary)
                    PaywallFeatureRow(icon: "star.fill",                  text: "Full gamification + XP",     color: SLTheme.Colors.accent)
                }
                .padding(.horizontal, SLTheme.Spacing.md)
                .padding(.vertical, SLTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, SLTheme.Spacing.xl)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)

                Spacer(minLength: SLTheme.Spacing.md)

                // ── Plan selector ─────────────────────────────────────
                VStack(spacing: 8) {
                    ForEach(Array(allPlans.enumerated()), id: \.element.id) { index, plan in
                        let livePrice = rcPackages[plan.rcKey]?.localizedPriceString
                        PaywallPlanRow(
                            plan: plan,
                            displayPrice: livePrice ?? plan.fallbackPrice,
                            isSelected: selectedIndex == index,
                            onTap: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    selectedIndex = index
                                }
                                HapticFeedbackEngine.shared.triggerLightTap()
                            }
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.8).delay(0.25 + Double(index) * 0.05),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, SLTheme.Spacing.xl)

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .font(SLTheme.Typography.caption)
                        .foregroundStyle(SLTheme.Colors.warning)
                        .padding(.horizontal, SLTheme.Spacing.xl)
                        .padding(.top, SLTheme.Spacing.xs)
                }

                Spacer(minLength: SLTheme.Spacing.md)

                // ── CTA + legal ───────────────────────────────────────
                VStack(spacing: SLTheme.Spacing.xs) {
                    Button {
                        Task { await purchaseSelected() }
                    } label: {
                        HStack(spacing: SLTheme.Spacing.sm) {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.85)
                                    .frame(width: 20)
                            } else {
                                Image(systemName: selectedPlan.hasTrial ? "gift.fill" : "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(width: 20)
                            }
                            Text(ctaText)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(selectedPlan.badgeIsGold ? SLTheme.Colors.backgroundPrimary : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(ctaBackground)
                        .clipShape(RoundedRectangle(cornerRadius: SLTheme.Radius.lg))
                        .shadow(
                            color: (selectedPlan.badgeIsGold ? SLTheme.Colors.streakGold : SLTheme.Colors.primary).opacity(0.4),
                            radius: 12, y: 4
                        )
                    }
                    .disabled(isPurchasing)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selectedIndex)

                    Text(disclosureText)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(SLTheme.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: SLTheme.Spacing.xl) {
                        Button("Restore") { Task { await restorePurchases() } }
                        Link("Terms", destination: SLLegal.terms)
                        Link("Privacy", destination: SLLegal.privacy)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(SLTheme.Colors.textTertiary)

                    // Maybe Later — only on hard paywall, appears after 3s delay
                    if !allowDismiss {
                        Button("Maybe Later") { onContinue() }
                            .font(.system(size: 12))
                            .foregroundStyle(SLTheme.Colors.textTertiary.opacity(0.5))
                            .opacity(showMaybeLater ? 1 : 0)
                            .animation(.easeIn(duration: 0.4), value: showMaybeLater)
                    }
                }
                .padding(.horizontal, SLTheme.Spacing.xl)
                .padding(.bottom, SLTheme.Spacing.lg)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: appeared)
            }
        }
        .task { await loadOfferings() }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.05))
                appeared = true
                if !allowDismiss {
                    try? await Task.sleep(for: .seconds(3.0))
                    showMaybeLater = true
                }
            }
        }
    }

    // MARK: - CTA Background

    @ViewBuilder
    private var ctaBackground: some View {
        if isPurchasing {
            SLTheme.Colors.backgroundTertiary
        } else if selectedPlan.badgeIsGold {
            LinearGradient(
                colors: [SLTheme.Colors.streakGold, Color(hex: "FF9F0A")],
                startPoint: .leading, endPoint: .trailing
            )
        } else {
            LinearGradient(
                colors: [SLTheme.Colors.primary, Color(hex: "8B5CF6")],
                startPoint: .leading, endPoint: .trailing
            )
        }
    }

    // MARK: - Load Offerings

    private func loadOfferings() async {
        await PurchaseService.shared.fetchOfferings()
        guard let offering = PurchaseService.shared.offerings?.current else { return }

        var loaded: [String: Package] = [:]
        for plan in allPlans {
            if let pkg = offering.package(identifier: plan.rcKey) {
                loaded[plan.rcKey] = pkg
            }
        }
        // Only update if we actually found packages
        if !loaded.isEmpty {
            rcPackages = loaded
        }
    }

    // MARK: - Purchase

    private func purchaseSelected() async {
        let plan = allPlans[selectedIndex]

        // If RC package is available, use it; otherwise advance to app (sandbox/debug)
        if let pkg = rcPackages[plan.rcKey] {
            isPurchasing = true
            errorMessage = nil
            let success = await PurchaseService.shared.purchase(package: pkg)
            isPurchasing = false
            if success {
                onContinue()
            } else {
                errorMessage = String(localized: "Purchase failed. Please try again.")
            }
        } else {
            #if DEBUG
            // Sandbox/preview convenience only — never grant access without a
            // real purchase in Release builds.
            onContinue()
            #else
            errorMessage = String(localized: "Plans are loading. Please check your connection and try again.")
            #endif
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
            errorMessage = String(localized: "No active subscription found.")
        }
    }
}

// MARK: - Feature Row

private struct PaywallFeatureRow: View {
    let icon: String
    let text: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: SLTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 26)

            Text(text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color.opacity(0.8))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Plan Row

private struct PaywallPlanRow: View {
    let plan: PlanConfig
    let displayPrice: String
    let isSelected: Bool
    let onTap: () -> Void

    private var accentColor: Color {
        plan.badgeIsGold ? SLTheme.Colors.streakGold : SLTheme.Colors.primary
    }

    private var rowBg: Color {
        if plan.badgeIsGold {
            return isSelected ? SLTheme.Colors.streakGold.opacity(0.12) : SLTheme.Colors.streakGold.opacity(0.05)
        }
        return isSelected ? SLTheme.Colors.primary.opacity(0.1) : SLTheme.Colors.backgroundTertiary
    }

    private var borderColor: Color {
        if isSelected && plan.badgeIsGold { return SLTheme.Colors.streakGold.opacity(0.65) }
        if isSelected { return SLTheme.Colors.primary.opacity(0.5) }
        if plan.badgeIsGold { return SLTheme.Colors.streakGold.opacity(0.2) }
        return Color.clear
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {

                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? accentColor : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 12, height: 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isSelected)

                // Title + subtext
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(plan.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(plan.badgeIsGold ? Color(hex: "1A1A3E") : .white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(plan.badgeIsGold ? SLTheme.Colors.streakGold : SLTheme.Colors.primary)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 4) {
                        Text(displayPrice + plan.period)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(SLTheme.Colors.textSecondary)

                        if plan.hasTrial {
                            Text("·")
                                .foregroundStyle(SLTheme.Colors.textTertiary)
                                .font(.system(size: 12))
                            Text("3-day free trial")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(SLTheme.Colors.accent)
                        }
                    }
                }

                Spacer()

                // Savings badge
                if let savings = plan.savings {
                    Text(savings)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(SLTheme.Colors.energyGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(SLTheme.Colors.energyGreen.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, SLTheme.Spacing.md)
            .padding(.vertical, SLTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                    .fill(rowBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: SLTheme.Radius.lg)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
