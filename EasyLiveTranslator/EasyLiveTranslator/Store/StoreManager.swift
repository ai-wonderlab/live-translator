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
        "com.aiwonderlab.easylivetranslator.hours.1",
        "com.aiwonderlab.easylivetranslator.hours.5",
        "com.aiwonderlab.easylivetranslator.hours.20",
        "com.aiwonderlab.easylivetranslator.hours.50",
    ]

    static let secondsPerProduct = [
        "com.aiwonderlab.easylivetranslator.hours.1": 3600,
        "com.aiwonderlab.easylivetranslator.hours.5": 18000,
        "com.aiwonderlab.easylivetranslator.hours.20": 72000,
        "com.aiwonderlab.easylivetranslator.hours.50": 180000,
    ]

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseState: PurchaseState = .idle

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
