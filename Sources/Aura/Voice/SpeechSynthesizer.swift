import AVFoundation
import AppKit

/// Manages voice output using native macOS AVSpeechSynthesizer with immediate barge-in interruption.
@MainActor
public final class SpeechSynthesizer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = SpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()
    @Published public var isSpeaking: Bool = false

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks the given text using the highest-quality available system voice.
    public func speak(text: String, onFinished: (@Sendable () -> Void)? = nil) {
        // Immediate interruption of prior speech
        stopSpeaking()

        let spokenEnabled = UserDefaults.standard.object(forKey: "spokenFeedbackEnabled") != nil ? UserDefaults.standard.bool(forKey: "spokenFeedbackEnabled") : true
        guard spokenEnabled else {
            AppState.shared.state = .speaking(text: text)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if case .speaking = AppState.shared.state {
                    AppState.shared.resetToIdle()
                }
            }
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        let rate = UserDefaults.standard.object(forKey: "speechRate") != nil ? Float(UserDefaults.standard.double(forKey: "speechRate")) : (AVSpeechUtteranceDefaultSpeechRate * 1.05)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0

        // Select preferred voice from user settings or fallback to default
        if let savedId = UserDefaults.standard.string(forKey: "selectedVoiceIdentifier"),
           let voice = AVSpeechSynthesisVoice(identifier: savedId) {
            utterance.voice = voice
        } else if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        isSpeaking = true
        AppState.shared.state = .speaking(text: text)
        AudioDuckingManager.shared.duckMedia()

        synthesizer.speak(utterance)
    }

    /// Barge-in: immediately halts any in-progress speech playback.
    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        AudioDuckingManager.shared.unduckMedia()
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            let wordLength = Float(characterRange.length)
            let intensity = min(1.0, max(0.40, wordLength * 0.12))
            AppState.shared.audioLevel = intensity
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                if case .speaking = AppState.shared.state {
                    AppState.shared.audioLevel = 0.22
                }
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            AppState.shared.audioLevel = 0.0
            AudioDuckingManager.shared.unduckMedia()
            if case .speaking = AppState.shared.state {
                AppState.shared.completeSpeakingAndPresent()
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            AppState.shared.audioLevel = 0.0
            AudioDuckingManager.shared.unduckMedia()
        }
    }
}
