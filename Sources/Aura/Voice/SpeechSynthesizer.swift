import AVFoundation
import AppKit

public enum TTSProvider: String, CaseIterable, Identifiable {
    case apple = "apple"
    case groq = "groq"
    case elevenlabs = "elevenlabs"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .apple: return "Apple Native (macOS Voices)"
        case .groq: return "Groq Orpheus (Turbo LPU)"
        case .elevenlabs: return "ElevenLabs Voice Synthesis"
        }
    }
}

/// Manages voice output across Apple Native, Groq Orpheus, and ElevenLabs TTS,
/// featuring real-time visualizer envelope tracking, media ducking, and immediate barge-in interruption.
@MainActor
public final class SpeechSynthesizer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = SpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()
    @Published public var isSpeaking: Bool = false

    private var envelopeTask: Task<Void, Never>? = nil
    private var targetLevel: Float = 0.0
    private var currentLevel: Float = 0.0
    private var currentSynthesisTask: Task<Void, Never>? = nil

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    public var currentProvider: TTSProvider {
        let saved = UserDefaults.standard.string(forKey: "ttsEngine") ?? "apple"
        return TTSProvider(rawValue: saved) ?? .apple
    }

    /// Speaks the given text using the configured TTS provider.
    public func speak(text: String, onFinished: (@Sendable () -> Void)? = nil) {
        // Immediate interruption of prior speech
        stopSpeaking()

        let spokenEnabled = UserDefaults.standard.object(forKey: "spokenFeedbackEnabled") != nil ? UserDefaults.standard.bool(forKey: "spokenFeedbackEnabled") : true
        guard spokenEnabled else {
            AppState.shared.state = .speaking(text: text)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if case .speaking = AppState.shared.state {
                    AppState.shared.resetToIdle()
                }
            }
            return
        }

        switch currentProvider {
        case .apple:
            speakWithApple(text: text, onFinished: onFinished)
        case .groq:
            speakWithGroq(text: text, onFinished: onFinished)
        case .elevenlabs:
            speakWithElevenLabs(text: text, onFinished: onFinished)
        }
    }

    /// Barge-in: immediately halts any in-progress speech synthesis or playback.
    public func stopSpeaking() {
        currentSynthesisTask?.cancel()
        currentSynthesisTask = nil

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        CloudAudioPlayer.shared.stop()

        isSpeaking = false
        stopEnvelopeTracking()
        AudioDuckingManager.shared.unduckMedia()
    }

    // MARK: - Apple Native TTS
    private func speakWithApple(text: String, onFinished: (@Sendable () -> Void)?) {
        let utterance = AVSpeechUtterance(string: text)
        let rate = UserDefaults.standard.object(forKey: "speechRate") != nil ? Float(UserDefaults.standard.double(forKey: "speechRate")) : (AVSpeechUtteranceDefaultSpeechRate * 1.05)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0

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

    // MARK: - Groq Orpheus TTS
    private func speakWithGroq(text: String, onFinished: (@Sendable () -> Void)?) {
        let apiKey = getGroqTTSApiKey()
        guard !apiKey.isEmpty else {
            NSLog("Aura: Groq TTS API key missing.")
            AppState.shared.state = .error(message: "Missing Groq TTS API Key.")
            return
        }

        let voice = UserDefaults.standard.string(forKey: "groqTTSVoice") ?? "autumn"

        isSpeaking = true
        AppState.shared.state = .speaking(text: text)
        AudioDuckingManager.shared.duckMedia()

        currentSynthesisTask = Task {
            do {
                guard let url = URL(string: "https://api.groq.com/openai/v1/audio/speech") else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let payload: [String: Any] = [
                    "model": "canopylabs/orpheus-v1-english",
                    "voice": voice,
                    "input": String(text.prefix(250)),
                    "response_format": "wav"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)

                let (data, response) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled else { return }

                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    let err = String(data: data, encoding: .utf8) ?? "HTTP error"
                    NSLog("Aura: Groq TTS error: %@", err)
                    AppState.shared.state = .error(message: "Groq TTS failed.")
                    return
                }

                CloudAudioPlayer.shared.play(data: data, spokenText: text, onFinished: onFinished)
            } catch {
                guard !Task.isCancelled else { return }
                NSLog("Aura: Groq TTS exception: %@", error.localizedDescription)
                AppState.shared.state = .error(message: "Groq TTS failed.")
            }
        }
    }

    // MARK: - ElevenLabs TTS
    private func speakWithElevenLabs(text: String, onFinished: (@Sendable () -> Void)?) {
        let apiKey = getElevenLabsTTSApiKey()
        guard !apiKey.isEmpty else {
            NSLog("Aura: ElevenLabs TTS API key missing.")
            AppState.shared.state = .error(message: "Missing ElevenLabs TTS API Key.")
            return
        }

        let voiceId = UserDefaults.standard.string(forKey: "elevenLabsTTSVoiceId") ?? "EXAVITQu4vr4xnSDxMaL"
        let modelId = UserDefaults.standard.string(forKey: "elevenLabsTTSModel") ?? "eleven_flash_v2_5"

        isSpeaking = true
        AppState.shared.state = .speaking(text: text)
        AudioDuckingManager.shared.duckMedia()

        currentSynthesisTask = Task {
            do {
                guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)") else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let payload: [String: Any] = [
                    "text": text,
                    "model_id": modelId
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)

                let (data, response) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled else { return }

                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    let err = String(data: data, encoding: .utf8) ?? "HTTP error"
                    NSLog("Aura: ElevenLabs TTS error: %@", err)
                    AppState.shared.state = .error(message: "ElevenLabs TTS failed.")
                    return
                }

                CloudAudioPlayer.shared.play(data: data, spokenText: text, onFinished: onFinished)
            } catch {
                guard !Task.isCancelled else { return }
                NSLog("Aura: ElevenLabs TTS exception: %@", error.localizedDescription)
                AppState.shared.state = .error(message: "ElevenLabs TTS failed.")
            }
        }
    }

    // MARK: - Key Helpers with Environment Variable Fallback
    public func getGroqTTSApiKey() -> String {
        let saved = UserDefaults.standard.string(forKey: "groqTTSApiKey")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !saved.isEmpty { return saved }
        return ProcessInfo.processInfo.environment["GROQ_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    public func getElevenLabsTTSApiKey() -> String {
        let saved = UserDefaults.standard.string(forKey: "elevenLabsTTSApiKey")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !saved.isEmpty { return saved }
        let env = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? ProcessInfo.processInfo.environment["XI_API_KEY"]
        return env?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: - Dynamic Vocal Envelope Modulation for Apple TTS
    private func startEnvelopeTracking() {
        envelopeTask?.cancel()
        currentLevel = 0.0
        targetLevel = 0.0
        envelopeTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_000_000) // ~30 FPS
                guard let self = self, self.isSpeaking else { break }

                let smoothing: Float = 0.32
                self.currentLevel += (self.targetLevel - self.currentLevel) * smoothing

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

        let clampedLen = Float(min(12, max(1, wordLength)))
        let intensity: Float = min(0.92, 0.40 + (clampedLen * 0.05))

        Task { @MainActor in
            if hasPunctuationPause {
                self.targetLevel = 0.04
            } else {
                self.targetLevel = intensity
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.stopEnvelopeTracking()
            AudioDuckingManager.shared.unduckMedia()
            if case .speaking = AppState.shared.state {
                AppState.shared.resetToIdle()
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.stopEnvelopeTracking()
            AudioDuckingManager.shared.unduckMedia()
            if case .speaking = AppState.shared.state {
                AppState.shared.resetToIdle()
            }
        }
    }
}
