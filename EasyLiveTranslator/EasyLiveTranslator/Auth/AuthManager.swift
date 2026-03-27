import Foundation
import Supabase
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var user: User? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    var isSignedIn: Bool { user != nil }

    private init() {
        Task { await refreshSession() }
    }

    func refreshSession() async {
        do {
            let session = try await supabase.auth.session
            self.user = session.user
        } catch {
            self.user = nil
        }
    }

    // MARK: Email / Password

    func signUp(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let session = try await supabase.auth.signUp(email: email, password: password)
            self.user = session.user
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            self.user = session.user
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: Apple Sign In

    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true; errorMessage = nil
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            self.user = session.user
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: Sign Out

    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
