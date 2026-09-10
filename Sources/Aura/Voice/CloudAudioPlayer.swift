import AVFoundation
import AppKit

/// Plays audio data (WAV / MP3) returned from cloud TTS providers (Groq Orpheus, ElevenLabs),
/// with real-time RMS metering for the glowing fluid visualizer orb and immediate barge-in interruption.
@MainActor
public final class CloudAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    public static let shared = CloudAudioPlayer()

    private var player: AVAudioPlayer?
    private var meterTask: Task<Void, Never>?
    private var onFinishedCallback: (@Sendable () -> Void)?

    @Published public private(set) var isPlaying: Bool = false

    private override init() {
        super.init()
    }

    /// Plays audio data with metering and automatic ducking.
    public func play(data: Data, spokenText: String, onFinished: (@Sendable () -> Void)? = nil) {
        stop()

        self.onFinishedCallback = onFinished

        do {
            let audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.delegate = self
            audioPlayer.isMeteringEnabled = true
            audioPlayer.prepareToPlay()

            self.player = audioPlayer
            self.isPlaying = true

            AppState.shared.state = .speaking(text: spokenText)
            AudioDuckingManager.shared.duckMedia()

            audioPlayer.play()
            startMetering(audioPlayer)
        } catch {
            NSLog("Aura: CloudAudioPlayer playback initialization failed: %@", error.localizedDescription)
            AppState.shared.state = .error(message: "Failed to play voice audio.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if case .error = AppState.shared.state {
                    AppState.shared.resetToIdle()
                }
            }
        }
    }

    /// Halts playback immediately (barge-in).
    public func stop() {
        if let p = player, p.isPlaying {
            p.stop()
        }
        player = nil
        isPlaying = false
        stopMetering()
        AudioDuckingManager.shared.unduckMedia()
    }

    // MARK: - Dynamic Vocal Metering for Orb Animation
    private func startMetering(_ audioPlayer: AVAudioPlayer) {
        meterTask?.cancel()
        meterTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_000_000) // ~30 FPS
                guard let self = self, self.isPlaying, let p = self.player, p.isPlaying else { break }

                p.updateMeters()
                let avgPower = p.averagePower(forChannel: 0) // [-160, 0] dB
                // Convert decibels to a normalized 0.0 - 1.0 linear amplitude
                let minDb: Float = -50.0
                let normalized: Float
                if avgPower < minDb {
                    normalized = 0.0
                } else {
                    normalized = max(0.0, min(1.0, (avgPower - minDb) / (-minDb)))
                }

                AppState.shared.audioLevel = normalized
            }
            AppState.shared.audioLevel = 0.0
        }
    }

    private func stopMetering() {
        meterTask?.cancel()
        meterTask = nil
        AppState.shared.audioLevel = 0.0
    }

    // MARK: - AVAudioPlayerDelegate
    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stop()
            if case .speaking = AppState.shared.state {
                AppState.shared.resetToIdle()
            }
            self.onFinishedCallback?()
            self.onFinishedCallback = nil
        }
    }

    public nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.stop()
            if case .speaking = AppState.shared.state {
                AppState.shared.resetToIdle()
            }
        }
    }
}
