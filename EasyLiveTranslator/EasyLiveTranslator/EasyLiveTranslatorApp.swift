import SwiftUI
import StoreKit
import Supabase
import AuthenticationServices
import CryptoKit

// MARK: - Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://ctrddyzybgeyipsslznw.supabase.co")!,
    supabaseKey: "sb_publishable_1-mGhNHxlREzyaG2XkWn-w_HUo9Z4Yj"
)

// MARK: - AuthManager

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var user: User? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    var isSignedIn: Bool { user != nil }

    private init() { Task { await refreshSession() } }

    func refreshSession() async {
        do { self.user = try await supabase.auth.session.user } catch { self.user = nil }
    }

    func signUp(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do { self.user = try await supabase.auth.signUp(email: email, password: password).user }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do { self.user = try await supabase.auth.signIn(email: email, password: password).user }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true; errorMessage = nil
        do {
            self.user = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            ).user
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // Called from SwiftUI — passes the webAuthenticationSession environment value
    func signInWithGoogle(launchFlow: @escaping @MainActor (URL) async throws -> URL) async {
        isLoading = true; errorMessage = nil
        do {
            try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "easylive://auth-callback")!,
                launchFlow: launchFlow
            )
            await refreshSession()
        } catch {
            let msg = error.localizedDescription
            if msg.localizedCaseInsensitiveContains("provider") || msg.localizedCaseInsensitiveContains("not enabled") {
                errorMessage = "Google Sign In is coming soon."
            } else {
                errorMessage = msg
            }
        }
        isLoading = false
    }

    func signOut() async {
        try? await supabase.auth.signOut(); self.user = nil
    }

    /// Deletes the user's account (App Store Guideline 5.1.1(v)).
    /// Requires the `delete_user` SECURITY DEFINER function in Supabase —
    /// see SETUP-ACCOUNT-DELETION.md.
    func deleteAccount() async {
        isLoading = true; errorMessage = nil
        do {
            try await supabase.rpc("delete_user").execute()
            try? await supabase.auth.signOut()
            self.user = nil
        } catch {
            errorMessage = "Could not delete account. Please try again or contact support."
            print("[Auth] Account deletion failed: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

// MARK: - AuthSheet

struct AuthSheet: View {
    @ObservedObject private var auth = AuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var nonce = ""

    enum AuthMode { case signIn, signUp }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.10).ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 24)
                VStack(spacing: 8) {
                    Text("🌐").font(.system(size: 44))
                    Text(mode == .signIn ? "Welcome back" : "Create account")
                        .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Text("30 minutes free · No credit card required")
                        .font(.system(size: 13, design: .rounded)).foregroundStyle(.white.opacity(0.5))
                }.padding(.bottom, 32)

                VStack(spacing: 12) {
                    SignInWithAppleButton(
                        mode == .signIn ? .signIn : .signUp,
                        onRequest: { req in
                            let n = randomNonce(); nonce = n
                            req.requestedScopes = [.fullName, .email]
                            req.nonce = sha256(n)
                        },
                        onCompletion: { result in
                            if case .success(let a) = result,
                               let cred = a.credential as? ASAuthorizationAppleIDCredential,
                               let tok = cred.identityToken,
                               let str = String(data: tok, encoding: .utf8) {
                                Task { await AuthManager.shared.signInWithApple(idToken: str, nonce: nonce) }
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50).cornerRadius(12)

                    // Google Sign In button
                    Button {
                        Task {
                            await auth.signInWithGoogle { url in
                                try await webAuthenticationSession.authenticate(
                                    using: url,
                                    callbackURLScheme: "easylive"
                                )
                            }
                            if auth.isSignedIn { dismiss() }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "globe")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                            Text("Continue with Google")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color(red: 0.25, green: 0.25, blue: 0.28))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    .disabled(auth.isLoading)

                    HStack {
                        Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                        Text("or").font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
                        Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                    }

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress).autocapitalization(.none)
                        .padding(14).background(Color.white.opacity(0.07)).cornerRadius(12).foregroundStyle(.white)
                    SecureField("Password", text: $password)
                        .padding(14).background(Color.white.opacity(0.07)).cornerRadius(12).foregroundStyle(.white)

                    if let err = auth.errorMessage {
                        Text(err).font(.system(size: 12)).foregroundStyle(.red.opacity(0.8)).multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            if mode == .signIn { await auth.signIn(email: email, password: password) }
                            else { await auth.signUp(email: email, password: password) }
                            if auth.isSignedIn { dismiss() }
                        }
                    } label: {
                        ZStack {
                            if auth.isLoading { ProgressView().tint(.black) }
                            else {
                                Text(mode == .signIn ? "Sign In" : "Create Account")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color(red: 0.20, green: 0.82, blue: 0.90)).cornerRadius(12)
                    }
                    .disabled(auth.isLoading || email.isEmpty || password.isEmpty)

                    Button { mode = mode == .signIn ? .signUp : .signIn; auth.errorMessage = nil } label: {
                        Text(mode == .signIn ? "Don't have an account? Sign up" : "Already have an account? Sign in")
                            .font(.system(size: 13, design: .rounded)).foregroundStyle(.white.opacity(0.5))
                    }
                }.padding(.horizontal, 24)
                Spacer()
            }
        }
    }

    private func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<length).map { _ in charset.randomElement()! })
    }
    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - PaywallSheet

struct PaywallSheet: View {
    @ObservedObject var storeManager: StoreManager
    @ObservedObject private var auth = AuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showAuth = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.10).ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 24)
                VStack(spacing: 10) {
                    Text("⏱️").font(.system(size: 48))
                    Text("Your free 30 minutes are up")
                        .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white).multilineTextAlignment(.center)
                    Text("Buy translation time to continue.\nNo subscription — hours never expire.")
                        .font(.system(size: 14, design: .rounded)).foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center)
                }.padding(.horizontal, 24).padding(.bottom, 28)

                if case .failed(let message) = storeManager.purchaseState {
                    Text(message)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24).padding(.bottom, 12)
                }

                if storeManager.products.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView().tint(.white)
                        Text("Loading plans...")
                            .font(.system(size: 13, design: .rounded)).foregroundStyle(.white.opacity(0.4))
                    }.padding(.vertical, 32)
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
                    }.padding(.horizontal, 24).padding(.bottom, 24)
                }

                if isPurchasing {
                    ProgressView().tint(Color(red: 0.20, green: 0.82, blue: 0.90)).padding(.bottom, 12)
                }

                // Optional — account is not required to purchase (credits sync via iCloud)
                if !auth.isSignedIn {
                    Button { showAuth = true } label: {
                        Text("Have an account? Sign in")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }.padding(.bottom, 8)
                }
                Spacer()
            }
        }
        .task {
            if storeManager.products.isEmpty { await storeManager.loadProducts() }
        }
        .onChange(of: storeManager.purchaseState) { _, state in
            if case .success = state { dismiss() }
        }
        .sheet(isPresented: $showAuth) {
            AuthSheet().presentationDetents([.large])
        }
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
                Text("Charged by recorded second")
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Text(product.displayPrice)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.20, green: 0.82, blue: 0.90))
        }
        .padding(14).background(Color.white.opacity(0.06)).cornerRadius(12)
    }
}


// MARK: - ProfileSheet

struct ProfileSheet: View {
    @ObservedObject private var auth = AuthManager.shared
    @ObservedObject private var credits = CreditManager.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var showPaywall: Bool
    @State private var showAuth = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.10).ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 28)

                if auth.isSignedIn {
                    // Logged in state
                    VStack(spacing: 20) {
                        // Avatar
                        ZStack {
                            Circle().fill(Color(red: 0.20, green: 0.82, blue: 0.90).opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(Color(red: 0.20, green: 0.82, blue: 0.90))
                        }

                        Text(auth.user?.email ?? "Account")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        // Plan badge
                        HStack(spacing: 6) {
                            Circle().fill(credits.hasCredits ?
                                Color(red: 0.20, green: 0.82, blue: 0.90) : .red)
                                .frame(width: 8, height: 8)
                            Text(credits.hasCredits ? "Active Plan" : "No Credits")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.white.opacity(0.07), in: Capsule())

                        // Credits remaining
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(Color(red: 0.20, green: 0.82, blue: 0.90))
                            Text(credits.remainingMinutesText)
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                            Spacer()
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showPaywall = true
                                }
                            } label: {
                                Text("Buy time")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Color(red: 0.20, green: 0.82, blue: 0.90), in: Capsule())
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 24)

                        // Sign out
                        Button {
                            Task { await auth.signOut(); dismiss() }
                        } label: {
                            Text("Sign Out")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.red.opacity(0.8))
                                .frame(maxWidth: .infinity).frame(height: 46)
                                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)

                        // Delete account — required by App Store Guideline 5.1.1(v)
                        Button { showDeleteConfirmation = true } label: {
                            Text("Delete Account")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                        .padding(.top, 4)

                        if let err = auth.errorMessage {
                            Text(err)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(.red.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                } else {
                    // Not logged in
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.07)).frame(width: 72, height: 72)
                            Image(systemName: "person.fill")
                                .font(.system(size: 30)).foregroundStyle(.white.opacity(0.4))
                        }

                        Text("No account yet")
                            .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        Text("Optional — create an account to sync\nyour profile across devices.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 12)

                        // Credits remaining (free trial)
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundStyle(Color(red: 0.20, green: 0.82, blue: 0.90))
                            Text(credits.remainingMinutesText)
                                .font(.system(size: 14, design: .rounded)).foregroundStyle(.white.opacity(0.7))
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)

                        Button { showAuth = true } label: {
                            Text("Create Account / Sign In")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(Color(red: 0.20, green: 0.82, blue: 0.90))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showAuth) {
            AuthSheet().presentationDetents([.large])
        }
        .alert("Delete your account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await auth.deleteAccount()
                    if !auth.isSignedIn { dismiss() }
                }
            }
        } message: {
            Text("This permanently deletes your account. Purchased translation time stays on this device and iCloud.")
        }
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

        // Handle deep link if app was launched via URL (OAuth callback)
        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let urlContext = URLContexts.first {
            handleURL(urlContext.url)
        }
    }

    private func handleURL(_ url: URL) {
        Task {
            do {
                try await supabase.auth.session(from: url)
                await AuthManager.shared.refreshSession()
            } catch {
                print("[Auth] Deep link handling failed: \(error)")
            }
        }
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
