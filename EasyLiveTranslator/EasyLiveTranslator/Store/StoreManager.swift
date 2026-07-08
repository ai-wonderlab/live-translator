import Foundation
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing(String)
        case success(String)
        case failed(String)
    }

    static let productIDs = [
        "gr.easyfair.credits.1h",
        "gr.easyfair.credits.5h",
        "gr.easyfair.credits.10h",
        "gr.easyfair.credits.50h",
    ]

    static let secondsPerProduct = [
        "gr.easyfair.credits.1h": 3600,
        "gr.easyfair.credits.5h": 18000,
        "gr.easyfair.credits.10h": 36000,
        "gr.easyfair.credits.50h": 180000,
    ]

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseState: PurchaseState = .idle

    private var updatesTask: Task<Void, Never>?

    init() {
        // Listen for transactions that arrive outside a direct purchase() call:
        // interrupted purchases, Ask to Buy approvals, purchases from other devices.
        // Without this, paid credits can be silently lost.
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.credit(result)
            }
        }
        // Credit any transactions left unfinished by a previous session (e.g. app killed mid-purchase).
        Task { [weak self] in
            for await result in Transaction.unfinished {
                await self?.credit(result)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    /// Verifies, credits, and finishes a transaction delivered outside purchase().
    private func credit(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        guard transaction.revocationDate == nil else {
            await transaction.finish()
            return
        }
        let seconds = Self.secondsPerProduct[transaction.productID] ?? 0
        if seconds > 0 {
            CreditManager.shared.addSeconds(seconds)
            purchaseState = .success("+\(seconds / 60) min added")
        }
        await transaction.finish()
    }

    func loadProducts() async {
        purchaseState = .loading

        do {
            let loadedProducts = try await Product.products(for: Self.productIDs)
            products = loadedProducts.sorted { lhs, rhs in
                (Self.secondsPerProduct[lhs.id] ?? 0) < (Self.secondsPerProduct[rhs.id] ?? 0)
            }
            purchaseState = .idle
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing(product.displayName)

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                let seconds = Self.secondsPerProduct[product.id] ?? 0
                guard seconds > 0 else {
                    purchaseState = .failed("Unknown credit pack.")
                    await transaction.finish()
                    return
                }

                CreditManager.shared.addSeconds(seconds)
                await transaction.finish()
                purchaseState = .success("+\(seconds / 60) min added")
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .failed("Purchase pending approval.")
            @unknown default:
                purchaseState = .failed("Purchase failed.")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    /// Consumables cannot be restored from the App Store — finished consumable
    /// transactions never appear in currentEntitlements. Credits live in iCloud
    /// Key-Value storage, so "restore" means re-reading them from iCloud, plus
    /// finishing any unfinished transactions that were never credited.
    func restorePurchases() async {
        purchaseState = .loading

        for await result in Transaction.unfinished {
            await credit(result)
        }

        CreditManager.shared.refreshFromStorage()
        purchaseState = .success("Credits synced from iCloud.")
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signedType):
            return signedType
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed."
        }
    }
}
