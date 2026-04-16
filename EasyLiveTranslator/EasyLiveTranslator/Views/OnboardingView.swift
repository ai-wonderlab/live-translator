import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentStep = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.078, green: 0.078, blue: 0.086)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    if currentStep == 0 { StepFeel() }
                    if currentStep == 1 { StepLanguages() }
                    if currentStep == 2 { StepPricing() }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentStep)
                .frame(maxWidth: 340)
                .padding(.horizontal, 24)

                Spacer()

                // Step indicators
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(i == currentStep ? 0.6 : 0.2))
                            .frame(width: i == currentStep ? 16 : 6, height: 6)
                            .animation(.easeInOut(duration: 0.25), value: currentStep)
                    }
                }
                .padding(.bottom, 28)

                // CTA button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if currentStep < 2 {
                            currentStep += 1
                        } else {
                            onComplete()
                        }
                    }
                } label: {
                    Text(currentStep < 2 ? "Next" : "Get Started")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Step 1: Feel it first

private struct StepFeel: View {
    var body: some View {
        VStack(spacing: 24) {
            WireSphere(state: .recording)
                .frame(width: 120, height: 120)

            MicCapsule(state: .recording, isPressed: true)
                .allowsHitTesting(false)

            VStack(spacing: 8) {
                Text("Hold to speak.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Release. Hear the translation.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Step 2: Languages

private let onboardingFlags = ["🇬🇷", "🇺🇸", "🇪🇸", "🇫🇷", "🇸🇦", "🇯🇵"]

private struct StepLanguages: View {
    var body: some View {
        VStack(spacing: 28) {
            LazyVGrid(columns: [GridItem(), GridItem(), GridItem()], spacing: 16) {
                ForEach(onboardingFlags, id: \.self) { flag in
                    Text(flag)
                        .font(.system(size: 36))
                        .frame(width: 52, height: 52)
                        .background(Color.white.opacity(0.055), in: Circle())
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                }
            }
            .frame(width: 200)

            VStack(spacing: 8) {
                Text("20 languages.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Switch anytime. The app detects who's speaking.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Step 3: Pricing

private struct StepPricing: View {
    private let plans: [(name: String, detail: String, price: String)] = [
        ("1 Hour", "1h of translation", "€0.99"),
        ("5 Hours", "5h of translation", "€3.99"),
    ]

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                ForEach(plans, id: \.name) { plan in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(plan.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(plan.detail)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                        Spacer()
                        Text(plan.price)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.20, green: 0.82, blue: 0.90))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                    .scaleEffect(0.8)
                    .opacity(0.7)
                }
            }

            VStack(spacing: 8) {
                Text("Pay for what you use.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("15 minutes free. No subscription.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
        }
    }
}
