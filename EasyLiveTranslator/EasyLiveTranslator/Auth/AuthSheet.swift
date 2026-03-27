import SwiftUI
import AuthenticationServices
import CryptoKit

struct AuthSheet: View {
    @ObservedObject private var auth = AuthManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var nonce = ""

    enum Mode { case signIn, signUp }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.10).ignoresSafeArea()
            VStack(spacing: 0) {
                // Handle
                Capsule().fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4).padding(.top, 12).padding(.bottom, 24)

                // Header
                VStack(spacing: 8) {
                    Text("🌐").font(.system(size: 44))
                    Text(mode == .signIn ? "Welcome back" : "Create account")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("30 minutes free · No credit card required")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 32)

                VStack(spacing: 12) {
                    // Apple Sign In
                    SignInWithAppleButton(
                        mode == .signIn ? .signIn : .signUp,
                        onRequest: { request in
                            let n = randomNonceString()
                            nonce = n
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(n)
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let auth):
                                guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                                      let tokenData = cred.identityToken,
                                      let token = String(data: tokenData, encoding: .utf8) else { return }
                                Task { await AuthManager.shared.signInWithApple(idToken: token, nonce: nonce) }
                            case .failure:
                                break
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(12)

                    // Divider
                    HStack {
                        Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                        Text("or").font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
                        Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                    }

                    // Email
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(14)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)
                        .foregroundStyle(.white)

                    // Password
                    SecureField("Password", text: $password)
                        .padding(14)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)
                        .foregroundStyle(.white)

                    if let err = auth.errorMessage {
                        Text(err).font(.system(size: 12)).foregroundStyle(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }

                    // Primary button
                    Button {
                        Task {
                            if mode == .signIn {
                                await auth.signIn(email: email, password: password)
                            } else {
                                await auth.signUp(email: email, password: password)
                            }
                            if auth.isSignedIn { dismiss() }
                        }
                    } label: {
                        ZStack {
                            if auth.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text(mode == .signIn ? "Sign In" : "Create Account")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color(red: 0.20, green: 0.82, blue: 0.90))
                        .cornerRadius(12)
                    }
                    .disabled(auth.isLoading || email.isEmpty || password.isEmpty)

                    // Toggle mode
                    Button {
                        mode = mode == .signIn ? .signUp : .signIn
                        auth.errorMessage = nil
                    } label: {
                        Text(mode == .signIn ? "Don't have an account? Sign up" : "Already have an account? Sign in")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    // MARK: Apple nonce helpers
    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<length).map { _ in charset.randomElement()! })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
