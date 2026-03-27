import SwiftUI

// MARK: - Design System

private enum DS {
    static let bg            = Color(red: 0.030, green: 0.038, blue: 0.065)
    static let bgMid         = Color(red: 0.048, green: 0.058, blue: 0.095)
    static let surface       = Color.white.opacity(0.055)
    static let border        = Color.white.opacity(0.08)
    static let borderBright  = Color.white.opacity(0.14)
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary  = Color.white.opacity(0.25)
    static let accent        = Color(red: 0.20, green: 0.82, blue: 0.90)
    static let accentSoft    = Color(red: 0.20, green: 0.82, blue: 0.90).opacity(0.15)
    static let accentGlow    = Color(red: 0.20, green: 0.82, blue: 0.90).opacity(0.28)
    static let recording     = Color(red: 0.95, green: 0.35, blue: 0.30)
    static let recordingGlow = Color(red: 0.95, green: 0.35, blue: 0.30).opacity(0.30)
    static let speaking      = Color(red: 0.30, green: 0.88, blue: 0.60)
    static let speakingGlow  = Color(red: 0.30, green: 0.88, blue: 0.60).opacity(0.28)
    static let translating   = Color(red: 0.55, green: 0.45, blue: 0.95)
    static let translatingGlow = Color(red: 0.55, green: 0.45, blue: 0.95).opacity(0.32)
}

// MARK: - Shared Mic State

enum MicState: Equatable { case idle, recording, translating, speaking }

extension MicState {
    var accentColor: Color {
        switch self {
        case .idle: return DS.accent
        case .recording: return DS.recording
        case .translating: return DS.translating
        case .speaking: return DS.speaking
        }
    }
    var glowColor: Color {
        switch self {
        case .idle: return DS.accentGlow
        case .recording: return DS.recordingGlow
        case .translating: return DS.translatingGlow
        case .speaking: return DS.speakingGlow
        }
    }
    var label: String {
        switch self {
        case .idle: return "HOLD TO TALK"
        case .recording: return "LISTENING"
        case .translating: return "TRANSLATING"
        case .speaking: return "SPEAKING"
        }
    }
    var icon: String {
        switch self {
        case .idle, .recording: return "mic.fill"
        case .translating: return "ellipsis"
        case .speaking: return "speaker.wave.2.fill"
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @StateObject private var engine = TranslationEngine()
    @ObservedObject private var credits = CreditManager.shared
    @StateObject private var storeManager = StoreManager()
    @AppStorage("sourceLang") private var sourceLanguageCode = Language.greek.code
    @AppStorage("targetLang") private var targetLanguageCode = Language.english.code
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @State private var showingLanguageSheet = false
    @State private var showingCreditsSheet  = false
    @State private var showOnboarding = false
    @GestureState private var isPressingMic = false

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            ambientBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                Spacer(minLength: 12)
                sphereSection
                Spacer(minLength: 12)
                translationCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                creditsRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            .padding(.top, 4)
        }
        .preferredColorScheme(.dark)
        .task {
            engine.sourceLanguage = sourceLanguage
            engine.targetLanguage = targetLanguage
            await engine.prepareForLaunch()
            await storeManager.loadProducts()
            if !hasSeenOnboarding { showOnboarding = true }
        }
        .onChange(of: sourceLanguageCode) { _, _ in engine.sourceLanguage = sourceLanguage }
        .onChange(of: targetLanguageCode) { _, _ in engine.targetLanguage = targetLanguage }
        .sheet(isPresented: $showingLanguageSheet) {
            LanguagePickerSheet(sourceLanguageCode: $sourceLanguageCode, targetLanguageCode: $targetLanguageCode)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingCreditsSheet) {
            CreditsPurchaseSheet(storeManager: storeManager, credits: credits)
                .presentationDetents([.fraction(0.48), .medium])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { hasSeenOnboarding = true; showOnboarding = false }
        }
    }

    // MARK: Ambient background glow

    private var ambientBackground: some View {
        ZStack {
            Ellipse()
                .fill(micState.glowColor)
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(y: -10)
                .animation(.easeInOut(duration: 0.7), value: micState)

            LinearGradient(
                colors: [DS.bgMid.opacity(0.5), .clear],
                startPoint: .top, endPoint: .center
            ).ignoresSafeArea()
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        Button { showingLanguageSheet = true } label: {
            HStack(spacing: 12) {
                // Auto-detect badge
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.accent)
                    Text("AUTO")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(DS.accent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DS.accentSoft, in: Capsule())
                .overlay(Capsule().strokeBorder(DS.accent.opacity(0.2), lineWidth: 1))

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.textTertiary)

                // Target language
                HStack(spacing: 8) {
                    Text(targetLanguage.flag).font(.system(size: 22))
                    Text(targetLanguage.displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.textTertiary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(DS.borderBright, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Sphere + mic

    private var sphereSection: some View {
        VStack(spacing: 16) {
            WireSphere(state: micState)
                .frame(width: 165, height: 165)

            // Detected language badge
            if let detected = engine.detectedLanguage {
                HStack(spacing: 6) {
                    Text(detected.flag).font(.system(size: 13))
                    Text(detected.displayName + " detected")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(DS.accent)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(DS.accentSoft, in: Capsule())
                .overlay(Capsule().strokeBorder(DS.accent.opacity(0.2), lineWidth: 1))
                .transition(.scale.combined(with: .opacity))
            }

            Text(statusLine)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(engine.errorMessage == nil ? DS.textSecondary : DS.recording)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
                .animation(.easeInOut(duration: 0.2), value: statusLine)

            MicCapsule(state: micState, isPressed: isPressingMic)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isPressingMic) { _, s, _ in s = true }
                        .onChanged { _ in engine.beginHoldIfNeeded() }
                        .onEnded { _ in Task { await engine.endHold() } }
                )
        }
    }

    // MARK: Translation card

    private var translationCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if engine.transcript.isEmpty && engine.translationText.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 15))
                        .foregroundStyle(DS.textTertiary)
                    Text("Translation will appear here")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(DS.textTertiary)
                }
            } else {
                if !engine.translationText.isEmpty {
                    cardLabel("Translation", icon: "text.bubble", color: DS.accent.opacity(0.85))
                    Text(engine.translationText)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.textPrimary)
                        .lineLimit(4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(DS.border, lineWidth: 1))
        .animation(.easeInOut(duration: 0.3), value: engine.translationText)
    }

    private func cardLabel(_ title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .tracking(0.8)
            .padding(.bottom, 4)
    }

    // MARK: Credits row

    private var creditsRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill").font(.system(size: 12)).foregroundStyle(DS.accent)
            Text(credits.remainingMinutesText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.textSecondary)
            Spacer()
            Button { showingCreditsSheet = true } label: {
                Label("Add time", systemImage: "plus")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.accent)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(DS.accentSoft, in: Capsule())
                    .overlay(Capsule().strokeBorder(DS.accent.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DS.border, lineWidth: 1))
    }

    // MARK: Helpers

    private var sourceLanguage: Language { Language(code: sourceLanguageCode) ?? .greek   }
    private var targetLanguage: Language { Language(code: targetLanguageCode) ?? .english }

    private var micState: MicState {
        if engine.isListening  { return .recording }
        if engine.isProcessing && !engine.translationText.isEmpty { return .speaking }
        if engine.isProcessing { return .translating }
        return .idle
    }

    private var statusLine: String {
        if engine.isPreparingPermissions { return "Requesting access..." }
        if let e = engine.errorMessage   { return e }
        switch micState {
        case .idle:        return engine.permissionsGranted ? "Hold to speak" : "Microphone access required"
        case .recording:   return "Listening..."
        case .translating: return "Translating..."
        case .speaking:    return "Speaking..."
        }
    }
}

// MARK: - Wire Sphere

struct WireSphere: View {
    let state: MicState

    @State private var rot1: Double = 0
    @State private var rot2: Double = 0
    @State private var breath: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Soft ambient glow
            Circle()
                .fill(state.glowColor)
                .blur(radius: 40)
                .scaleEffect(breath * 1.15)

            // Wire rings
            ZStack {
                ring(opacity: 0.55, wRatio: 1.0, hRatio: 0.38, extraDeg: 0,   rot: rot1)
                ring(opacity: 0.38, wRatio: 1.0, hRatio: 0.38, extraDeg: 55,  rot: rot1)
                ring(opacity: 0.25, wRatio: 1.0, hRatio: 0.38, extraDeg: 110, rot: rot1)
                ring(opacity: 0.45, wRatio: 0.38, hRatio: 1.0, extraDeg: 0,   rot: rot2)
                ring(opacity: 0.28, wRatio: 0.38, hRatio: 1.0, extraDeg: 50,  rot: rot2)

                // Outer circle outline
                Circle()
                    .stroke(state.accentColor.opacity(0.18), lineWidth: 0.7)

                // Inner radial glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [state.accentColor.opacity(0.16), .clear],
                            center: .center, startRadius: 0, endRadius: 80
                        )
                    )
                    .scaleEffect(0.75)
                    .scaleEffect(breath)

                // Center icon
                Image(systemName: state.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(state.accentColor)
                    .shadow(color: state.glowColor, radius: 12)
            }
            .scaleEffect(breath)
        }
        .onAppear { animate() }
        .onChange(of: state) { _, _ in animate() }
    }

    private func ring(opacity: Double, wRatio: CGFloat, hRatio: CGFloat, extraDeg: Double, rot: Double) -> some View {
        GeometryReader { geo in
            let w = geo.size.width * wRatio
            let h = geo.size.height * hRatio
            Ellipse()
                .stroke(state.accentColor.opacity(opacity), lineWidth: 1.0)
                .frame(width: w, height: h)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .rotationEffect(.degrees(rot + extraDeg))
        }
    }

    private func animate() {
        let fast = state != .idle
        let spd1: Double = fast ? 4.5 : 14.0
        let spd2: Double = fast ? 6.0 : 18.0
        let bDur: Double = fast ? 1.2 : 3.2
        let bAmt: CGFloat = fast ? 1.10 : 1.04

        withAnimation(.linear(duration: spd1).repeatForever(autoreverses: false)) { rot1 = 360 }
        withAnimation(.linear(duration: spd2).repeatForever(autoreverses: false)) { rot2 = -360 }
        withAnimation(.easeInOut(duration: bDur).repeatForever(autoreverses: true)) { breath = bAmt }
    }
}

// MARK: - Mic Capsule

struct MicCapsule: View {
    let state: MicState
    let isPressed: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: state.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(labelForeground)
            Text(state.label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(labelForeground)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(state.accentColor, in: Capsule())
        .overlay(Capsule().strokeBorder(state.accentColor.opacity(0.3), lineWidth: 1))
        .shadow(color: state.glowColor, radius: state == .idle ? 14 : 26)
        .scaleEffect(isPressed ? 0.93 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.6), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: state)
    }

    private var labelForeground: Color {
        // Cyan is light enough — use dark text. Others use white.
        state == .idle ? DS.bg : .white
    }
}

// MARK: - Language Picker Sheet

struct LanguagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sourceLanguageCode: String
    @Binding var targetLanguageCode: String
    @State private var search = ""

    private var filtered: [Language] {
        search.isEmpty ? Language.allCases
            : Language.allCases.filter { $0.displayName.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { lang in
                Button { select(lang) } label: {
                    HStack(spacing: 14) {
                        Text(lang.flag).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.displayName)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(DS.textPrimary)
                            Text(lang.localeIdentifier)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(DS.textTertiary)
                        }
                        Spacer()
                        if sourceLanguageCode == lang.code { badgeView("FROM", DS.accent) }
                        else if targetLanguageCode == lang.code { badgeView("TO", DS.speaking) }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(sourceLanguageCode == lang.code || targetLanguageCode == lang.code
                              ? DS.accentSoft : DS.surface)
                        .padding(.vertical, 2)
                )
            }
            .listStyle(.plain)
            .background(DS.bg)
            .scrollContentBackground(.hidden)
            .searchable(text: $search, prompt: "Search")
            .navigationTitle("Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(DS.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func badgeView(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(1.2)
            .foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }

    private func select(_ lang: Language) {
        if sourceLanguageCode == lang.code {
            targetLanguageCode = lang.code == Language.english.code ? Language.greek.code : Language.english.code
            return
        }
        sourceLanguageCode = lang.code
        if targetLanguageCode == lang.code {
            targetLanguageCode = sourceLanguageCode == Language.english.code ? Language.greek.code : Language.english.code
        }
    }
}

// MARK: - Credits Sheet

struct CreditsPurchaseSheet: View {
    @ObservedObject var storeManager: StoreManager
    @ObservedObject var credits: CreditManager

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(Color.white.opacity(0.18)).frame(width: 40, height: 4).padding(.top, 10)
            VStack(spacing: 6) {
                Text("Add Translation Time")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill").font(.system(size: 12)).foregroundStyle(DS.accent)
                    Text(credits.displayTime)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(DS.textSecondary)
                }
            }
            if case .failed(let m) = storeManager.purchaseState {
                Text(m).font(.system(size: 13, design: .rounded)).foregroundStyle(DS.recording).multilineTextAlignment(.center).padding(.horizontal, 24)
            } else if case .success(let m) = storeManager.purchaseState {
                Text(m).font(.system(size: 13, design: .rounded)).foregroundStyle(DS.speaking)
            }
            if storeManager.products.isEmpty {
                Text("Loading products...").font(.system(size: 14, design: .rounded)).foregroundStyle(DS.textTertiary).padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(storeManager.products, id: \.id) { p in
                        Button { Task { await storeManager.purchase(p) } } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(p.displayName)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(DS.textPrimary)
                                    Text(durText(p.id))
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(DS.textTertiary)
                                }
                                Spacer()
                                Text(p.displayPrice)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(DS.accent)
                            }
                            .padding(.horizontal, 18).padding(.vertical, 14)
                            .background(DS.surface, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain).disabled(isPurchasing).padding(.horizontal, 20)
                    }
                }
            }
            if isPurchasing { ProgressView().tint(DS.accent) }
            Text("30 min free trial · 20 sec per translation")
                .font(.system(size: 12, design: .rounded)).foregroundStyle(DS.textTertiary).multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var isPurchasing: Bool {
        if case .purchasing = storeManager.purchaseState { return true }; return false
    }
    private func durText(_ id: String) -> String {
        let h = (StoreManager.secondsPerProduct[id] ?? 0) / 3600
        return "\(h) hour\(h == 1 ? "" : "s") of translation"
    }
}
