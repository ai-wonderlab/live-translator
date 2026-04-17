import Foundation

enum TranslationAPIError: LocalizedError {
    case missingAppSecret
    case noInternet
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingAppSecret:
            return "Translation API secret is missing from the app configuration."
        case .noInternet:
            return "No internet connection. Please check your network and try again."
        case .server(let message):
            return message
        }
    }
}

struct TranslationAPI {
    private let endpoint = URL(string: "https://backend-gamma-eight-88.vercel.app/api/translate")!

    func translate(
        text: String,
        langA: Language,
        langB: Language
    ) async throws -> TranslationResult {
        // Tier 1: Apple on-device translation (free, no network required)
        if #available(iOS 17.4, *) {
            let apple = AppleTranslationProvider()
            if let result = await apple.translate(text: text, langA: langA.code, langB: langB.code) {
                return result
            }
        }

        // Tier 2: Azure Translator via Vercel backend (fallback for unsupported languages)
        return try await callBackend(text: text, langA: langA, langB: langB)
    }

    private func callBackend(text: String, langA: Language, langB: Language) async throws -> TranslationResult {
        guard let appSecret = Bundle.main.object(forInfoDictionaryKey: "TranslationAPIAppSecret") as? String,
              !appSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationAPIError.missingAppSecret
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appSecret, forHTTPHeaderField: "X-App-Secret")
        request.httpBody = try JSONEncoder().encode(
            TranslateRequest(
                text: text,
                sourceLang: langA.code,
                targetLang: langB.code
            )
        )

        print("[API] → POST /translate (backend)")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError where [
            .notConnectedToInternet,
            .networkConnectionLost,
            .timedOut,
            .cannotConnectToHost,
            .dnsLookupFailed
        ].contains(urlError.code) {
            throw TranslationAPIError.noInternet
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            throw TranslationAPIError.server("Translation service rejected the app secret.")
        }

        if httpResponse.statusCode == 429 {
            throw TranslationAPIError.server("Translation service is temporarily rate limited.")
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(TranslationResult.self, from: data)
        if let apiError = result.error, !apiError.isEmpty {
            throw TranslationAPIError.server("Translation failed. Please try again.")
        }
        print("[API] ← {detected: \(result.detected), translation: \(result.translation)}")
        return result
    }
}

private struct TranslateRequest: Encodable {
    let text: String
    let sourceLang: String
    let targetLang: String
}
