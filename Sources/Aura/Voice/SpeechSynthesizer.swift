import AVFoundation
import AppKit

/// Manages voice output using native macOS AVSpeechSynthesizer with immediate barge-in interruption.
@MainActor
public final class SpeechSynthesizer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = SpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()
    @Published public var isSpeaking: Bool = false

    private var envelopeTask: Task<Void, Never>? = nil
    private var targetLevel: Float = 0.0
    private var currentLevel: Float = 0.0

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

        startEnvelopeTracking()
        synthesizer.speak(utterance)
    }

    /// Barge-in: immediately halts any in-progress speech playback.
    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        stopEnvelopeTracking()
        AudioDuckingManager.shared.unduckMedia()
    }

    // MARK: - Dynamic Vocal Envelope Modulation
    private func startEnvelopeTracking() {
        envelopeTask?.cancel()
        currentLevel = 0.0
        targetLevel = 0.0
        envelopeTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_000_000) // ~30 FPS
                guard let self = self, self.isSpeaking else { break }

                // Smooth exponential glide towards target level
                let smoothing: Float = 0.32
                self.currentLevel += (self.targetLevel - self.currentLevel) * smoothing

                // Natural cadence decay if target is sustained
                if self.targetLevel > 0.04 {
                    self.targetLevel = max(0.04, self.targetLevel * 0.91)
                }

                AppState.shared.audioLevel = self.currentLevel
            }
            AppState.shared.audioLevel = 0.0
        }
    }

    private func stopEnvelopeTracking() {
        envelopeTask?.cancel()
        envelopeTask = nil
        currentLevel = 0.0
        targetLevel = 0.0
        AppState.shared.audioLevel = 0.0
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let fullString = utterance.speechString as NSString
        let wordLength = characterRange.length
        let nextIndex = characterRange.location + characterRange.length

        var hasPunctuationPause = false
        if nextIndex < fullString.length {
            let checkLen = min(3, fullString.length - nextIndex)
            let snippet = fullString.substring(with: NSRange(location: nextIndex, length: checkLen))
            for char in snippet {
                if char == "," || char == "." || char == "?" || char == "!" || char == ";" || char == "—" {
                    hasPunctuationPause = true
                    break
                }
            }
        }

        // Fast intensity calculation
        let clampedLen = Float(min(12, max(1, wordLength)))
        let intensity: Float = min(0.92, 0.40 + (clampedLen * 0.05))

        Task { @MainActor in
            guard self.isSpeaking else { return }
            self.targetLevel = intensity

            if hasPunctuationPause {
                let delay = max(0.16, Double(clampedLen) * 0.05)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    if self?.isSpeaking == true {
                        self?.targetLevel = 0.02
                    }
                }
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.stopEnvelopeTracking()
            AudioDuckingManager.shared.unduckMedia()
            if case .speaking = AppState.shared.state {
                AppState.shared.completeSpeakingAndPresent()
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.stopEnvelopeTracking()
            AudioDuckingManager.shared.unduckMedia()
        }
    }
}
