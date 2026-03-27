import SwiftUI

struct HomeView: View {
    @StateObject private var engine = TranslationEngine()
    @ObservedObject private var credits = CreditManager.shared
    @StateObject private var storeManager = StoreManager()
    @AppStorage("sourceLang") private var sourceLanguageCode = Language.greek.code
    @AppStorage("targetLang") private var targetLanguageCode = Language.english.code
    @State private var showingLanguageSheet = false
    @State private var showingCreditsSheet = false
    @GestureState private var isPressingMic = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Language picker — top
                HStack(spacing: 14) {
                    Button {
                        showingLanguageSheet = true
                    } label: {
                        languageBadge(sourceLanguage)
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.swapLanguages()
                        sourceLanguageCode = engine.sourceLanguage.code
                        targetLanguageCode = engine.targetLanguage.code
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(10)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(engine.isListening || engine.isProcessing)

                    Button {
                        showingLanguageSheet = true
                    } label: {
                        languageBadge(targetLanguage)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Spacer()

                // Mic section — center
                VStack(spacing: 18) {
                    WaveformRow(isAnimating: engine.isListening)

                    MicButton(state: micState, isPressed: isPressingMic)
                        .contentShape(Circle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($isPressingMic) { _, state, _ in
                                    state = true
                                }
                                .onChanged { _ in
                                    engine.beginHoldIfNeeded()
                                }
                                .onEnded { _ in
                                    Task {
                                        await engine.endHold()
                                    }
                                }
                        )
                        .accessibilityLabel("Hold to talk")

                    Text(statusLine)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(statusColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }

                Spacer()

                // Translation history — bottom
                TranslationHistoryView(history: engine.history)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            CreditsRow(
                minutesText: credits.remainingMinutesText,
                onAdd: { showingCreditsSheet = true }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0), Color.black.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .preferredColorScheme(.dark)
        .task {
            engine.sourceLanguage = sourceLanguage
            engine.targetLanguage = targetLanguage
            await engine.prepareForLaunch()
            await storeManager.loadProducts()
        }
        .onChange(of: sourceLanguageCode) { _, _ in
            engine.sourceLanguage = sourceLanguage
        }
        .onChange(of: targetLanguageCode) { _, _ in
            engine.targetLanguage = targetLanguage
        }
        .sheet(isPresented: $showingLanguageSheet) {
            LanguagePickerSheet(
                sourceLanguageCode: $sourceLanguageCode,
                targetLanguageCode: $targetLanguageCode
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingCreditsSheet) {
            CreditsPurchaseSheet(storeManager: storeManager, credits: credits)
                .presentationDetents([.fraction(0.42), .medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var sourceLanguage: Language {
        Language(code: sourceLanguageCode) ?? .greek
    }

    private var targetLanguage: Language {
        Language(code: targetLanguageCode) ?? .english
    }

    private var micState: MicButton.State {
        if engine.isListening {
            return .recording
        }
        if engine.isProcessing && !engine.translationText.isEmpty {
            return .speaking
        }
        if engine.isProcessing {
            return .translating
        }
        return .idle
    }

    private var statusLine: String {
        if engine.isPreparingPermissions {
            return "Requesting microphone and speech recognition access..."
        }
        if let errorMessage = engine.errorMessage {
            return errorMessage
        }
        switch micState {
        case .idle:
            return engine.permissionsGranted
                ? "Hold to speak. Release to translate."
                : "Allow access to microphone and speech recognition to continue."
        case .recording:
            return "Listening in \(sourceLanguage.displayName)."
        case .translating:
            return "Translating to \(targetLanguage.displayName)."
        case .speaking:
            return "Speaking in \(targetLanguage.displayName)."
        }
    }

    private var statusColor: Color {
        engine.errorMessage == nil ? .white.opacity(0.64) : .red.opacity(0.85)
    }



    private func languageBadge(_ language: Language) -> some View {
        HStack(spacing: 10) {
            Text(language.flag)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                Text(language.displayName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(language.localeIdentifier)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WaveformRow: View {
    let isAnimating: Bool

    // idle heights give a recognizable "audio bar" silhouette — not dots
    private let idleHeights: [CGFloat] = [10, 16, 10]
    private let activeHeights: [CGFloat] = [16, 28, 20]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(isAnimating ? 0.85 : 0.25))
                    .frame(width: 4, height: isAnimating ? activeHeights[index] : idleHeights[index])
                    .animation(
                        isAnimating
                            ? .easeInOut(duration: 0.55).repeatForever().delay(Double(index) * 0.08)
                            : .easeInOut(duration: 0.2),
                        value: isAnimating
                    )
            }
        }
        .frame(height: 28)
    }
}

private struct CreditsRow: View {
    let minutesText: String
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label(minutesText, systemImage: "clock")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.76))

            Spacer()

            Button(action: onAdd) {
                Text("[+]")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct LanguagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sourceLanguageCode: String
    @Binding var targetLanguageCode: String

    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Language.allCases) { language in
                        Button {
                            select(language)
                        } label: {
                            HStack(spacing: 10) {
                                Text(language.flag)
                                    .font(.system(size: 28))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(language.displayName)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)

                                    Text(language.localeIdentifier)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.45))
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(cellBackground(for: language))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Languages")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func select(_ language: Language) {
        if sourceLanguageCode == language.code {
            targetLanguageCode = language.code == Language.english.code ? Language.greek.code : Language.english.code
            return
        }

        sourceLanguageCode = language.code

        if targetLanguageCode == language.code {
            targetLanguageCode = sourceLanguageCode == Language.english.code ? Language.greek.code : Language.english.code
        }
    }

    private func cellBackground(for language: Language) -> Color {
        let isSelected = sourceLanguageCode == language.code || targetLanguageCode == language.code
        return isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.05)
    }
}

private struct TranslationHistoryView: View {
    let history: [TranslationEntry]

    var body: some View {
        Group {
            if history.isEmpty {
                VStack(spacing: 8) {
                    Text("Your translations will appear here.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.34))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .padding(20)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(history) { entry in
                            TranslationEntryRow(entry: entry)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 240)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
    }
}

private struct TranslationEntryRow: View {
    let entry: TranslationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(entry.sourceLanguage.flag)
                    .font(.system(size: 13))
                Text(entry.spokenText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                Text(entry.targetLanguage.flag)
                    .font(.system(size: 15))
                Text(entry.translatedText)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 8)
    }
}


private struct CreditsPurchaseSheet: View {
    @ObservedObject var storeManager: StoreManager
    @ObservedObject var credits: CreditManager

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.18))
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            Text("Add Credits")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text(credits.displayTime)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))

            if case .failed(let message) = storeManager.purchaseState {
                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.red.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            } else if case .success(let message) = storeManager.purchaseState {
                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.green.opacity(0.88))
            }

            if storeManager.products.isEmpty {
                Text("Products load from App Store Connect or a StoreKit configuration in sandbox.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.64))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            } else {
                ForEach(storeManager.products, id: \.id) { product in
                    Button {
                        Task {
                            await storeManager.purchase(product)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.displayName)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text(packDurationText(for: product.id))
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                            }

                            Spacer()

                            Text(product.displayPrice)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing)
                    .padding(.horizontal, 20)
                }
            }

            if isPurchasing {
                ProgressView()
                    .tint(.white)
            }

            Text("Free trial: 30 min. Each translation deducts 20 sec.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var isPurchasing: Bool {
        if case .purchasing = storeManager.purchaseState {
            return true
        }

        return false
    }

    private func packDurationText(for productID: String) -> String {
        let seconds = StoreManager.secondsPerProduct[productID] ?? 0
        let hours = seconds / 3600
        return "\(hours) hour\(hours == 1 ? "" : "s")"
    }
}
