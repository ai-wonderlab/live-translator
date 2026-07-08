import SwiftUI
import StoreKit

struct PaywallSheet: View {
    @ObservedObject var storeManager: StoreManager
    @ObservedObject private var auth = AuthManager.shared
    @ObservedObject private var credits = CreditManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showAuth = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.10).ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 24)

                // Icon + title
                VStack(spacing: 10) {
                    Text("⏱️").font(.system(size: 48))
                    Text("Your free 30 minutes are up")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("Buy translation time to continue.\nNo subscription — hours never expire.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Purchase feedback
                if case .failed(let message) = storeManager.purchaseState {
                    Text(message)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }

                // Plans — real StoreKit products
                if storeManager.products.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView().tint(.white)
                        Text("Loading plans...")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.vertical, 32)
                } else {
                    VStack(spacing: 10) {
                        ForEach(storeManager.products, id: \.id) { product in
                            Button {
                                Task { await storeManager.purchase(product) }
                            } label: {
                                planRow(product: product)
                            }
                            .buttonStyle(.plain)
                            .disabled(isPurchasing)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                if isPurchasing {
                    ProgressView().tint(Color(red: 0.20, green: 0.82, blue: 0.90))
                        .padding(.bottom, 12)
                }

                // Optional account — not required for purchase
                if !auth.isSignedIn {
                    Button { showAuth = true } label: {
                        Text("Have an account? Sign in")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.bottom, 8)
                }

                Spacer()
            }
        }
        .task {
            if storeManager.products.isEmpty {
                await storeManager.loadProducts()
            }
        }
        .onChange(of: storeManager.purchaseState) { _, state in
            if case .success = state { dismiss() }
        }
        .sheet(isPresented: $showAuth) {
            AuthSheet()
                .presentationDetents([.large])
        }
    }

    private var isPurchasing: Bool {
        if case .purchasing = storeManager.purchaseState { return true }
        return false
    }

    @ViewBuilder
    private func planRow(product: Product) -> some View {
        let seconds = StoreManager.secondsPerProduct[product.id] ?? 0
        let hours = seconds / 3600
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(hours) hour\(hours > 1 ? "s" : "")")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("~\(hours * 180) translations")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Text(product.displayPrice)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.20, green: 0.82, blue: 0.90))
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}
