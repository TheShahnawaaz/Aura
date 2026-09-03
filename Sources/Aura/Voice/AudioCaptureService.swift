@preconcurrency import AVFoundation
import Foundation

/// Captures audio from the default input device at 16kHz Mono and publishes audio levels.
/// Runs CoreAudio operations outside the MainActor to guarantee realtime thread safety.
public final class AudioCaptureService: @unchecked Sendable {
    public static let shared = AudioCaptureService()

    private let lock = NSLock()
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var isRecording: Bool = false

    public typealias AudioBufferHandler = @Sendable (AVAudioPCMBuffer) -> Void

    public init() {}

    /// Starts microphone audio capture.
    public func startCapture(onBuffer: AudioBufferHandler? = nil) throws {
        lock.lock()
        defer { lock.unlock() }

        guard !isRecording else { return }

        let engine = AVAudioEngine()
        self.audioEngine = engine
        let input = engine.inputNode
        self.inputNode = input

        let inputFormat = input.outputFormat(forBus: 0)

        // Ensure valid format from hardware
        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            throw AudioCaptureError.invalidAudioFormat
        }

        // Desired format: 16 kHz Mono Float32 (Whisper standard)
        guard let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioCaptureError.invalidAudioFormat
        }

        guard let formatConverter = AVAudioConverter(from: inputFormat, to: recordingFormat) else {
            throw AudioCaptureError.converterInitializationFailed
        }

        let handler = onBuffer
        input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, _ in
            let level = AudioCaptureService.calculateRMS(buffer: buffer)
            Task { @MainActor in
                AppState.shared.audioLevel = level
            }

            // Convert to 16kHz Mono buffer for STT engine
            let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: recordingFormat,
                frameCapacity: AVAudioFrameCount(recordingFormat.sampleRate * 0.1)
            )

            if let convertedBuffer {
                var error: NSError?
                formatConverter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }

                if error == nil {
                    handler?(convertedBuffer)
                }
            }
        }

        engine.prepare()
        try engine.start()
        isRecording = true
    }

    /// Stops audio capture and removes the tap.
    public func stopCapture() {
        lock.lock()
        defer { lock.unlock() }

        guard isRecording else { return }
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        isRecording = false

        Task { @MainActor in
            AppState.shared.audioLevel = 0.0
        }
    }

    /// Calculates RMS level normalized between 0.0 and 1.0.
    public static func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }

        var sum: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))
        // Perceptual audio scaling: logarithmic/power curve makes voice immediately responsive
        let boosted = pow(min(1.0, rms * 12.0), 0.7)
        return min(1.0, max(0.0, boosted))
    }
}

public enum AudioCaptureError: LocalizedError {
    case invalidAudioFormat
    case converterInitializationFailed

    public var errorDescription: String? {
        switch self {
        case .invalidAudioFormat:
            return "Failed to create 16kHz mono audio format or hardware not ready."
        case .converterInitializationFailed:
            return "Failed to initialize AVAudioConverter from microphone format."
        }
    }
}
