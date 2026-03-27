import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentStep = 0

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "mic.fill",
            iconColor: .red,
            title: "Hold to speak.",
            subtitle: "Press and hold the button, say something, release. You'll hear the translation instantly."
        ),
        OnboardingStep(
            icon: "globe",
            iconColor: .blue,
            title: "20 languages.",
            subtitle: "Switch between any two languages at any time — great for conversations on the go."
        ),
        OnboardingStep(
            icon: "clock",
            iconColor: .green,
            title: "Pay for what you use.",
            subtitle: "30 minutes free. No subscription — buy more time when you need it."
        ),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Step content
                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(steps[currentStep].iconColor.opacity(0.12))
                            .frame(width: 96, height: 96)
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(steps[currentStep].iconColor)
                    }

                    VStack(spacing: 12) {
                        Text(steps[currentStep].title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(steps[currentStep].subtitle)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 8)
                    }
                }
                .frame(maxWidth: 320)
                .padding(.horizontal, 24)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentStep)

                Spacer()

                // Step indicators
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(index == currentStep ? 0.85 : 0.22))
                            .frame(width: index == currentStep ? 20 : 7, height: 7)
                            .animation(.easeInOut(duration: 0.25), value: currentStep)
                    }
                }
                .padding(.bottom, 32)

                // CTA button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if currentStep < steps.count - 1 {
                            currentStep += 1
                        } else {
                            onComplete()
                        }
                    }
                } label: {
                    Text(currentStep < steps.count - 1 ? "Next" : "Get Started")
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
        .preferredColorScheme(.dark)
    }
}

private struct OnboardingStep {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
}
