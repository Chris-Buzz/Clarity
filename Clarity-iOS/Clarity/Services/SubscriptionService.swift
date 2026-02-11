import StoreKit
import Observation

/// Manages in-app subscriptions using StoreKit 2.
/// No server needed — Apple handles billing, receipts, renewal.
@Observable
class SubscriptionService {
    static let shared = SubscriptionService()

    // Product IDs (configure in App Store Connect)
    static let monthlyProductId = "com.clarity-focus.monthly"
    static let yearlyProductId = "com.clarity-focus.yearly"

    var products: [Product] = []
    var purchasedSubscription: Product? = nil
    var isSubscribed: Bool = false
    var subscriptionStatus: String = "none" // "monthly", "yearly", "none", "expired"

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    /// Load available products from App Store Connect
    func loadProducts() async {
        do {
            products = try await Product.products(for: [
                Self.monthlyProductId,
                Self.yearlyProductId,
            ])
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    /// Purchase a subscription
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    /// Check current subscription status
    func updateSubscriptionStatus() async {
        var hasActive = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == Self.monthlyProductId {
                    subscriptionStatus = "monthly"
                    hasActive = true
                } else if transaction.productID == Self.yearlyProductId {
                    subscriptionStatus = "yearly"
                    hasActive = true
                }
            }
        }

        isSubscribed = hasActive
        if !hasActive {
            subscriptionStatus = "none"
        }
    }

    /// Restore purchases (for "Restore Purchases" button in Settings)
    func restorePurchases() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    /// Listen for transaction updates (renewals, cancellations, refunds)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
