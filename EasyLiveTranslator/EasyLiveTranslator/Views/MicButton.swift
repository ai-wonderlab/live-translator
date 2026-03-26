import SwiftUI

struct MicButton: View {
    enum State {
        case idle
        case recording
        case translating
        case speaking
    }

    let state: State
    let isPressed: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
                .frame(width: 164, height: 164)
                .shadow(color: glowColor, radius: glowRadius)
                .scaleEffect(isPressed ? 1.03 : 1.0)

            VStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)

                Text(labelText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(1.4)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: state)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isPressed)
    }

    private var backgroundColor: Color {
        switch state {
        case .idle:
            return Color(white: 0.15)
        case .recording:
            return Color.red.opacity(0.8)
        case .translating:
            return Color.blue.opacity(0.6)
        case .speaking:
            return Color.green.opacity(0.5)
        }
    }

    private var glowColor: Color {
        switch state {
        case .recording:
            return Color.red.opacity(0.4)
        case .translating:
            return Color.blue.opacity(0.24)
        case .speaking:
            return Color.green.opacity(0.22)
        case .idle:
            return .clear
        }
    }

    private var glowRadius: CGFloat {
        switch state {
        case .recording:
            return 26
        case .translating, .speaking:
            return 16
        case .idle:
            return 0
        }
    }

    private var iconName: String {
        switch state {
        case .idle, .recording:
            return "mic.fill"
        case .translating:
            return "ellipsis"
        case .speaking:
            return "speaker.wave.2.fill"
        }
    }

    private var labelText: String {
        switch state {
        case .idle:
            return "HOLD TO TALK"
        case .recording:
            return "RECORDING"
        case .translating:
            return "TRANSLATING"
        case .speaking:
            return "SPEAKING"
        }
    }
}
