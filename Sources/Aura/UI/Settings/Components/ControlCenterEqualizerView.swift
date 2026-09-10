import SwiftUI

/// Real-time 16-bar responsive audio spectrum equalizer visualizer for Control Center.
public struct ControlCenterEqualizerView: View {
    public let audioLevel: Float
    public let barCount: Int
    public let height: CGFloat

    public init(audioLevel: Float, barCount: Int = 16, height: CGFloat = 24) {
        self.audioLevel = audioLevel
        self.barCount = barCount
        self.height = height
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                barView(for: index)
            }
        }
        .frame(height: height)
    }

    private func barView(for index: Int) -> some View {
        // Curve factor gives natural bell curve higher in center frequencies
        let normalized = Float(index) / Float(barCount - 1)
        let bellFactor = sin(normalized * .pi)
        let variation = Float((index * 7) % 5) / 10.0 // slight organic asymmetry

        let rawHeight = (Float(audioLevel) * 1.8 * (0.5 + bellFactor * 0.5 + variation))
        let clampedHeight = max(0.12, min(1.0, rawHeight))
        let targetHeight = CGFloat(clampedHeight) * height

        return RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        ControlCenterTokens.Colors.accentCyan,
                        ControlCenterTokens.Colors.accentIndigo,
                        ControlCenterTokens.Colors.accentPurple
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3.5, height: targetHeight)
            .animation(
                .interactiveSpring(response: 0.12, dampingFraction: 0.65),
                value: audioLevel
            )
    }
}
