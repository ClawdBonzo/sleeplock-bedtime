import Foundation
import StoreKit

// MARK: - RevenueCat Integration Point
// TODO: Add RevenueCat SDK via SPM: https://github.com/RevenueCat/purchases-ios
// Then uncomment the RevenueCat code below and add your API key.

/*
import RevenueCat

final class PurchaseService {
    static let shared = PurchaseService()

    private init() {}

    func configure() {
        Purchases.configure(
            with: .init(withAPIKey: "YOUR_REVENUECAT_PUBLIC_KEY")
                .with(usesStoreKit2IfAvailable: true)
        )
    }

    func getOfferings() async throws -> Offerings {
        try await Purchases.shared.offerings()
    }

    func purchase(package: Package) async throws -> (transaction: StoreTransaction?, customerInfo: CustomerInfo, userCancelled: Bool) {
        try await Purchases.shared.purchase(package: package)
    }

    func restorePurchases() async throws -> CustomerInfo {
        try await Purchases.shared.restorePurchases()
    }

    func checkSubscriptionStatus() async -> Bool {
        guard let customerInfo = try? await Purchases.shared.customerInfo() else {
            return false
        }
        return customerInfo.entitlements["premium"]?.isActive ?? false
    }
}
*/

// MARK: - Stub Purchase Service (works without RevenueCat for development)
@Observable
final class PurchaseService: @unchecked Sendable {
    static let shared = PurchaseService()

    var isPremium = false

    private init() {}

    func configure() {
        // Will be replaced with RevenueCat configuration
    }

    func purchase() async -> Bool {
        // Stub: simulate successful purchase
        isPremium = true
        return true
    }

    func restore() async -> Bool {
        // Stub: simulate restore
        isPremium = true
        return true
    }
}
