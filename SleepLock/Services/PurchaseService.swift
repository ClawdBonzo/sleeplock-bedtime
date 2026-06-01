import Foundation
import RevenueCat

@Observable
final class PurchaseService: @unchecked Sendable {
    static let shared = PurchaseService()

    private(set) var isPremium = false
    private(set) var offerings: Offerings?
    private(set) var customerInfo: CustomerInfo?

    private init() {}

    // MARK: - Configure
    func configure() {
        #if DEBUG
        // Screenshot / QA overrides — never compiled into Release builds.
        if CommandLine.arguments.contains("-ForcePremium") {
            isPremium = true
            return
        }
        if CommandLine.arguments.contains("-ForceFree") {
            isPremium = false
            return
        }
        #endif

        Purchases.configure(
            with: .init(withAPIKey: "appl_aPYYAojwFtMRdlQyrevFaEJEmnU")
                .with(usesStoreKit2IfAvailable: true)
        )
        Purchases.logLevel = .debug

        Task {
            await refreshStatus()
        }
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
    func purchase(package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                self.customerInfo = result.customerInfo
                self.isPremium = result.customerInfo.entitlements["pro"]?.isActive ?? false
                return true
            }
            return false
        } catch {
            print("[PurchaseService] Purchase failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Restore
    func restore() async -> Bool {
        do {
            let info = try await Purchases.shared.restorePurchases()
            self.customerInfo = info
            self.isPremium = info.entitlements["pro"]?.isActive ?? false
            return isPremium
        } catch {
            print("[PurchaseService] Restore failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Refresh Status
    func refreshStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            self.customerInfo = info
            self.isPremium = info.entitlements["pro"]?.isActive ?? false
        } catch {
            print("[PurchaseService] Status refresh failed: \(error.localizedDescription)")
        }
    }
}
