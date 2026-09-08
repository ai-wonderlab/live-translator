import SwiftUI
import StoreKit

// MARK: - Debug logging
// User speech/translations must never reach production logs (privacy policy: "we never store").

@inline(__always)
func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}

// MARK: - PaywallSheet
// The single purchase surface. Opened from "Add time", from the locked mic,
// and automatically when translation time reaches zero. No account required —
// credits live in iCloud Key-Value storage and follow the user's Apple ID.

struct PaywallSheet: View {
    @ObservedObject var storeManager: StoreManager
    @ObservedObject private var credits = CreditManager.shared
    @Environment(\.dismiss) private var dismiss

    private let accent = Color(red: 0.20, green: 0.82, blue: 0.90)

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.10).ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 24)
                VStack(spacing: 10) {
                    Text(credits.hasCredits ? "⏱️" : "⌛").font(.system(size: 48))
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white).multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(.system(size: 14, design: .rounded)).foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center)
                }.padding(.horizontal, 24).padding(.bottom, 20)

                // Current balance
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill").font(.system(size: 12)).foregroundStyle(accent)
                    Text(credits.remainingMinutesText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color.white.opacity(0.06), in: Capsule())
                .padding(.bottom, 20)

                if case .failed(let message) = storeManager.purchaseState {
                    Text(message)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24).padding(.bottom, 12)
                } else if case .success(let message) = storeManager.purchaseState {
                    Text(message)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Color(red: 0.30, green: 0.88, blue: 0.60))
                        .padding(.bottom, 12)
                }

                if storeManager.products.isEmpty {
                    VStack(spacing: 12) {
                        if storeManager.purchaseState == .loading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 22))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Text(storeManager.purchaseState == .loading ? "Loading plans..." : "Plans unavailable. Check your connection and try again.")
                            .font(.system(size: 13, design: .rounded)).foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                        if storeManager.purchaseState != .loading {
                            Button("Retry") { Task { await storeManager.loadProducts() } }
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(accent)
                        }
                    }.padding(.vertical, 24).padding(.horizontal, 24)
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
                    }.padding(.horizontal, 24).padding(.bottom, 16)
                }

                if isPurchasing {
                    ProgressView().tint(accent).padding(.bottom, 12)
                }

                Text("Time is charged only while you hold the button.\nHours never expire · No subscription")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                Button {
                    Task { await storeManager.restorePurchases() }
                } label: {
                    Text("Restore / sync from iCloud")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .disabled(isPurchasing)
                .padding(.bottom, 8)

                Spacer()
            }
        }
        .task {
            if storeManager.products.isEmpty { await storeManager.loadProducts() }
        }
        .onChange(of: storeManager.purchaseState) { _, state in
            // Dismiss only after a real purchase — a restore just shows its message.
            if case .success(let msg) = state, msg.hasPrefix("+") { dismiss() }
        }
    }

    private var title: String {
        if credits.hasCredits { return "Add translation time" }
        return credits.remainingSeconds == 0 && credits.freeTrialConsumedSeconds >= CreditManager.freeTrialSeconds && !credits.hasEverPurchased
            ? "Your free 30 minutes are up"
            : "You're out of translation time"
    }

    private var subtitle: String {
        credits.hasCredits
            ? "Top up now so you never run out mid-conversation."
            : "Buy translation time to continue."
    }

    private var isPurchasing: Bool {
        if case .purchasing = storeManager.purchaseState { return true }
        return false
    }

    @ViewBuilder
    private func planRow(product: Product) -> some View {
        let hours = (StoreManager.secondsPerProduct[product.id] ?? 0) / 3600
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(hours) hour\(hours > 1 ? "s" : "")")
                    .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                Text("of talk time")
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Text(product.displayPrice)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
        }
        .padding(14).background(Color.white.opacity(0.06)).cornerRadius(12)
    }
}

// MARK: - Scene Delegate

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let win = UIWindow(windowScene: windowScene)
        win.frame = windowScene.screen.bounds
        win.backgroundColor = .black
        let hostingController = UIHostingController(rootView: HomeView())
        hostingController.view.backgroundColor = .black
        win.rootViewController = hostingController
        win.makeKeyAndVisible()
        self.window = win
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// MARK: - App Entry Point

@main
struct EasyLiveTranslatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Window is managed by SceneDelegate — this body is intentionally empty.
        WindowGroup { EmptyView() }
    }
}
