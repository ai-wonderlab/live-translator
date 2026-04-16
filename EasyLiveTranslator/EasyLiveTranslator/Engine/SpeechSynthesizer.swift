import AVFoundation
import Foundation

@MainActor
final class SpeechSynthesizer: NSObject, @preconcurrency AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var completion: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // Not throws — withCheckedContinuation never throws
    func speak(_ text: String, language: Language) async {
        // Re-activate audio session for playback after recording deactivated it
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
        try? session.setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        // Try full locale first (e.g. "fr-FR"), fall back to language code (e.g. "fr"),
        // then any available voice for that language — avoids silent English fallback.
        let voice = AVSpeechSynthesisVoice(language: language.localeIdentifier)
            ?? AVSpeechSynthesisVoice(language: language.rawValue)
            ?? AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.hasPrefix(language.rawValue) })
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        print("[TTS] Speaking (\(language.localeIdentifier), voice: \(voice?.name ?? "nil")): \(text)")
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)

        await withCheckedContinuation { continuation in
            completion = continuation
        }

        // Let other audio resume after TTS finishes
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion?.resume()
        completion = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        completion?.resume()
        completion = nil
    }
}
