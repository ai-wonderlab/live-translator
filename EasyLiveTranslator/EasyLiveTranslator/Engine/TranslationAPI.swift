import Foundation

enum TranslationAPIError: LocalizedError {
    case missingAppSecret
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingAppSecret:
            return "Translation API secret is missing from the app configuration."
        case .server(let message):
            return message
        }
    }
}

struct TranslationAPI {
    private let endpoint = URL(string: "https://backend-gamma-eight-88.vercel.app/api/translate")!

    func translate(
        text: String,
        sourceLanguage: Language,
        targetLanguage: Language
    ) async throws -> TranslationResult {
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
                sourceLang: sourceLanguage.code,
                targetLang: targetLanguage.code
            )
        )

        print("[API] → POST /translate")
        let (data, response) = try await URLSession.shared.data(for: request)

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
