import Foundation
import RevenueCat

@Observable
final class PurchaseService: @unchecked Sendable {
    static let shared = PurchaseService()

    enum PurchaseOutcome {
        case success
        /// The user dismissed the payment sheet — not an error, show nothing.
        case cancelled
        /// Payment went through but the "pro" entitlement didn't activate
        /// (product not attached to the entitlement in RevenueCat).
        case entitlementInactive
        case failed
    }

    enum RestoreOutcome {
        case restored
        case nothingToRestore
        /// The App Store couldn't be reached — distinct from "no subscription".
        case failed
    }

    private(set) var isPremium = false
    private(set) var offerings: Offerings?
    private(set) var customerInfo: CustomerInfo?

    /// Set once the launch hard-paywall has been shown and dismissed, so
    /// RootView doesn't immediately present a second copy after onboarding.
    var hasSeenLaunchPaywallThisSession = false

    /// DEBUG QA override (-ForcePremium / -ForceFree): pins isPremium without
    /// skipping SDK configuration, so the paywall and offerings still work.
    private var premiumOverride: Bool?

    private init() {}

    // MARK: - Configure
    func configure() {
        #if DEBUG
        // Screenshot / QA overrides — never compiled into Release builds.
        if CommandLine.arguments.contains("-ForcePremium") {
            premiumOverride = true
            isPremium = true
        } else if CommandLine.arguments.contains("-ForceFree") {
            premiumOverride = false
            isPremium = false
        }
        #endif

        Purchases.configure(
            with: .init(withAPIKey: "appl_aPYYAojwFtMRdlQyrevFaEJEmnU")
                .with(storeKitVersion: .storeKit2)
        )
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Task {
            await refreshStatus()
        }
    }

    private func applyEntitlements(from info: CustomerInfo) {
        customerInfo = info
        let active = info.entitlements["pro"]?.isActive ?? false
        isPremium = premiumOverride ?? active
    }

    // MARK: - Fetch Offerings
    func fetchOfferings() async {
        do {
            self.offerings = try await Purchases.shared.offerings()
        } catch {
            print("[PurchaseService] Failed to fetch offerings: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase
    func purchase(package: Package) async -> PurchaseOutcome {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                return .cancelled
            }
            applyEntitlements(from: result.customerInfo)
            let entitled = result.customerInfo.entitlements["pro"]?.isActive ?? false
            return entitled ? .success : .entitlementInactive
        } catch {
            print("[PurchaseService] Purchase failed: \(error.localizedDescription)")
            return .failed
        }
    }

    // MARK: - Restore
    func restore() async -> RestoreOutcome {
        do {
            let info = try await Purchases.shared.restorePurchases()
            applyEntitlements(from: info)
            let entitled = info.entitlements["pro"]?.isActive ?? false
            return entitled ? .restored : .nothingToRestore
        } catch {
            print("[PurchaseService] Restore failed: \(error.localizedDescription)")
            return .failed
        }
    }

    // MARK: - Refresh Status
    func refreshStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            applyEntitlements(from: info)
        } catch {
            print("[PurchaseService] Status refresh failed: \(error.localizedDescription)")
        }
    }
}
