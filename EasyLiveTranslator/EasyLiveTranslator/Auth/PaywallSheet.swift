import SwiftUI

struct PaywallSheet: View {
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
                    Text("Create a free account to continue\nand purchase translation time.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Plans (placeholder — payment to be decided)
                VStack(spacing: 10) {
                    planRow(hours: 1,  price: "€0.99")
                    planRow(hours: 5,  price: "€3.99")
                    planRow(hours: 10, price: "€6.99")
                    planRow(hours: 50, price: "€24.99")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // CTA
                if auth.isSignedIn {
                    Button {
                        // TODO: trigger payment flow
                        dismiss()
                    } label: {
                        Text("Purchase Hours")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(Color(red: 0.20, green: 0.82, blue: 0.90))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                } else {
                    Button { showAuth = true } label: {
                        Text("Create Free Account")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(Color(red: 0.20, green: 0.82, blue: 0.90))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showAuth) {
            AuthSheet()
                .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private func planRow(hours: Int, price: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(hours) hour\(hours > 1 ? "s" : "")")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("~\(hours * 60) translations")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Text(price)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.20, green: 0.82, blue: 0.90))
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}
