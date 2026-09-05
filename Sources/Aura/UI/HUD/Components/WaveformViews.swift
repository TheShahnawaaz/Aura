import SwiftUI

/// Real-time audio waveform view that pulses with microphone input level with cyan-to-mint gradient.
public struct FluidWaveformView: View {
    public let audioLevel: Float

    public init(audioLevel: Float) {
        self.audioLevel = audioLevel
    }

    public var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<5) { index in
                Capsule()
                    .fill(HUDDesignTokens.Gradients.listeningWave)
                    .frame(
                        width: 2.5,
                        height: max(4, CGFloat(audioLevel) * 22 * CGFloat([0.5, 0.9, 1.25, 0.85, 0.45][index]))
                    )
                    .animation(HUDDesignTokens.Springs.audioReact, value: audioLevel)
                    .shadow(color: HUDDesignTokens.Colors.listeningCyan.opacity(0.4), radius: 2, y: 0)
            }
        }
        .frame(height: 16)
    }
}

/// Equalizer waveform view animated during speech synthesis with warm coral-to-peach gradient,
/// dynamically scaling with the synthesized speech audio level.
public struct SpeakingWaveformView: View {
    public let audioLevel: Float

    public init(audioLevel: Float = 0) {
        self.audioLevel = audioLevel
    }

    public var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<5) { index in
                let frequencyMultiplier: CGFloat = [0.45, 0.95, 1.30, 0.85, 0.50][index]
                let normalizedLevel = CGFloat(max(0.0, min(1.0, audioLevel)))
                let barHeight = max(3.5, normalizedLevel * 20.0 * frequencyMultiplier)

                Capsule()
                    .fill(HUDDesignTokens.Gradients.speakingWave)
                    .frame(width: 2.5, height: barHeight)
                    .animation(HUDDesignTokens.Springs.audioReact, value: audioLevel)
                    .shadow(
                        color: HUDDesignTokens.Colors.speakingCoral.opacity(Double(normalizedLevel) * 0.50),
                        radius: 2,
                        y: 0
                    )
            }
        }
        .frame(height: 16)
    }
}
