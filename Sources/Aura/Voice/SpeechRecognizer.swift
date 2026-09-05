@preconcurrency import AVFoundation
@preconcurrency import Speech
import Foundation

/// Real-time streaming Speech-to-Text recognizer using Apple's native SFSpeechRecognizer.
public final class NativeSpeechRecognizer: @unchecked Sendable {
    public static let shared = NativeSpeechRecognizer()

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let lock = NSLock()

    public init(locale: Locale = Locale.current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    /// Requests speech recognition authorization from macOS.
    public static func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                NSLog("Aura: Speech recognition authorized.")
            case .denied, .restricted, .notDetermined:
                NSLog("Aura: Speech recognition not authorized (status: %ld).", status.rawValue)
            @unknown default:
                break
            }
        }
    }

    /// Begins a live streaming recognition session.
    public func startRecognition(onTranscriptUpdate: @escaping @Sendable (String, Bool) -> Void) throws {
        lock.lock()
        defer { lock.unlock() }

        // Cancel previous task if still running
        cancelInternal()

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechRecognizerError.recognizerUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result {
                let transcription = result.bestTranscription.formattedString
                let isFinal = result.isFinal
                onTranscriptUpdate(transcription, isFinal)
            }
            if error != nil {
                // Audio ended or canceled
            }
        }
    }

    /// Appends an incoming audio buffer from the microphone tap.
    public func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        recognitionRequest?.append(buffer)
    }

    /// Ends audio stream and finalizes transcription.
    public func stopRecognition() {
        lock.lock()
        defer { lock.unlock() }

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.finish()
        recognitionTask = nil
    }

    /// Cancels audio stream and discards any partial transcription immediately.
    public func cancelRecognition() {
        lock.lock()
        defer { lock.unlock() }
        cancelInternal()
    }

    private func cancelInternal() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}

public enum SpeechRecognizerError: LocalizedError {
    case recognizerUnavailable

    public var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Apple Speech recognition service is currently unavailable. Please check system dictation settings."
        }
    }
}
