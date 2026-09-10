@preconcurrency import AVFoundation
import Foundation

public enum STTProvider: String, CaseIterable, Identifiable {
    case apple = "apple"
    case groq = "groq"
    case elevenlabs = "elevenlabs"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .apple: return "Apple Native (On-Device)"
        case .groq: return "Groq Whisper (Turbo LPU)"
        case .elevenlabs: return "ElevenLabs Scribe"
        }
    }
}

/// Unified Speech-to-Text router dynamically executing transcription via:
/// 1. Apple Native SFSpeechRecognizer (local on-device streaming)
/// 2. Groq Whisper (ultra-fast cloud LPU)
/// 3. ElevenLabs Scribe (cloud high-precision speech-to-text)
public final class SpeechRecognitionRouter: @unchecked Sendable {
    public static let shared = SpeechRecognitionRouter()

    private let lock = NSLock()
    private var accumulatedBuffers: [AVAudioPCMBuffer] = []
    private var isRecording: Bool = false
    private var onTranscriptUpdate: (@Sendable (String, Bool) -> Void)?

    private init() {}

    /// Current configured STT provider from settings
    public var currentProvider: STTProvider {
        let saved = UserDefaults.standard.string(forKey: "sttEngine") ?? "apple"
        return STTProvider(rawValue: saved) ?? .apple
    }

    /// Starts speech recognition session.
    public func startRecognition(onTranscriptUpdate: @escaping @Sendable (String, Bool) -> Void) throws {
        lock.lock()
        defer { lock.unlock() }

        self.accumulatedBuffers.removeAll()
        self.isRecording = true
        self.onTranscriptUpdate = onTranscriptUpdate

        switch currentProvider {
        case .apple:
            try NativeSpeechRecognizer.shared.startRecognition(onTranscriptUpdate: onTranscriptUpdate)
        case .groq, .elevenlabs:
            // For cloud STT, audio buffers are collected until speech ends/silence triggers stopRecognition.
            // Notify caller that listening is active.
            onTranscriptUpdate("", false)
        }
    }

    /// Ingests incoming audio buffer from microphone tap.
    public func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }

        guard isRecording else { return }

        switch currentProvider {
        case .apple:
            NativeSpeechRecognizer.shared.appendAudioBuffer(buffer)
        case .groq, .elevenlabs:
            // Clone/retain the buffer for cloud encoding
            if let copy = copyBuffer(buffer) {
                accumulatedBuffers.append(copy)
            }
        }
    }

    /// Stops audio capture and finalizes transcription.
    /// Delivers the final text via the completion handler.
    public func stopRecognition(completion: @escaping @Sendable (String) -> Void) {
        lock.lock()
        let provider = currentProvider
        let buffers = self.accumulatedBuffers
        self.accumulatedBuffers = []
        self.isRecording = false
        lock.unlock()

        switch provider {
        case .apple:
            NativeSpeechRecognizer.shared.stopRecognition()
            // NativeSpeechRecognizer sends final transcript through its own callback.
            completion("")
        case .groq:
            Task {
                let text = await self.transcribeWithGroq(buffers: buffers)
                completion(text)
            }
        case .elevenlabs:
            Task {
                let text = await self.transcribeWithElevenLabs(buffers: buffers)
                completion(text)
            }
        }
    }

    /// Cancels audio capture and discards any partial state.
    public func cancelRecognition() {
        lock.lock()
        accumulatedBuffers.removeAll()
        isRecording = false
        onTranscriptUpdate = nil
        lock.unlock()

        NativeSpeechRecognizer.shared.cancelRecognition()
    }

    // MARK: - Cloud Transcriptions
    private func transcribeWithGroq(buffers: [AVAudioPCMBuffer]) async -> String {
        guard let wavData = WAVAudioEncoder.encode(buffers: buffers) else {
            return ""
        }

        let apiKey = getGroqSTTApiKey()
        guard !apiKey.isEmpty else {
            NSLog("Aura: Groq STT API key is empty.")
            return ""
        }

        let model = UserDefaults.standard.string(forKey: "groqSTTModel") ?? "whisper-large-v3-turbo"
        guard let url = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions") else { return "" }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // Model
        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"model\"\r\n\r\n".utf8)
        body.append(contentsOf: "\(model)\r\n".utf8)
        // Response format
        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".utf8)
        body.append(contentsOf: "json\r\n".utf8)
        // File
        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".utf8)
        body.append(contentsOf: "Content-Type: audio/wav\r\n\r\n".utf8)
        body.append(wavData)
        body.append(contentsOf: "\r\n".utf8)
        body.append(contentsOf: "--\(boundary)--\r\n".utf8)

        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let err = String(data: data, encoding: .utf8) ?? "HTTP error"
                NSLog("Aura: Groq STT failed: %@", err)
                return ""
            }

            struct WhisperResp: Decodable { let text: String }
            let decoded = try JSONDecoder().decode(WhisperResp.self, from: data)
            return decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            NSLog("Aura: Groq STT request exception: %@", error.localizedDescription)
            return ""
        }
    }

    private func transcribeWithElevenLabs(buffers: [AVAudioPCMBuffer]) async -> String {
        guard let wavData = WAVAudioEncoder.encode(buffers: buffers) else {
            return ""
        }

        let apiKey = getElevenLabsSTTApiKey()
        guard !apiKey.isEmpty else {
            NSLog("Aura: ElevenLabs STT API key is empty.")
            return ""
        }

        let model = UserDefaults.standard.string(forKey: "elevenLabsSTTModel") ?? "scribe_v1"
        guard let url = URL(string: "https://api.elevenlabs.io/v1/speech-to-text") else { return "" }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // Model ID
        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"model_id\"\r\n\r\n".utf8)
        body.append(contentsOf: "\(model)\r\n".utf8)
        // File
        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".utf8)
        body.append(contentsOf: "Content-Type: audio/wav\r\n\r\n".utf8)
        body.append(wavData)
        body.append(contentsOf: "\r\n".utf8)
        body.append(contentsOf: "--\(boundary)--\r\n".utf8)

        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let err = String(data: data, encoding: .utf8) ?? "HTTP error"
                NSLog("Aura: ElevenLabs STT failed: %@", err)
                return ""
            }

            struct ScribeResp: Decodable { let text: String }
            let decoded = try JSONDecoder().decode(ScribeResp.self, from: data)
            return decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            NSLog("Aura: ElevenLabs STT request exception: %@", error.localizedDescription)
            return ""
        }
    }

    // MARK: - Key Helpers with Environment Variable Fallback
    private func getGroqSTTApiKey() -> String {
        let saved = UserDefaults.standard.string(forKey: "groqSTTApiKey")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !saved.isEmpty { return saved }
        return ProcessInfo.processInfo.environment["GROQ_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func getElevenLabsSTTApiKey() -> String {
        let saved = UserDefaults.standard.string(forKey: "elevenLabsSTTApiKey")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !saved.isEmpty { return saved }
        let env = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? ProcessInfo.processInfo.environment["XI_API_KEY"]
        return env?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func copyBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameCapacity) else { return nil }
        copy.frameLength = buffer.frameLength
        if let src = buffer.floatChannelData, let dst = copy.floatChannelData {
            for ch in 0..<Int(buffer.format.channelCount) {
                dst[ch].initialize(from: src[ch], count: Int(buffer.frameLength))
            }
        }
        return copy
    }
}
