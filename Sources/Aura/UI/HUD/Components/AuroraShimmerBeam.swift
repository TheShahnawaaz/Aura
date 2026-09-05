import SwiftUI

/// Fluid, GPU-accelerated progress beam with flowing multi-stop aurora gradient.
public struct AuroraShimmerBeam: View {
    @State private var phase: CGFloat = 0

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let beamWidth = max(50, width * 0.40)

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 2.5)

                // Shimmering multi-stop gradient beam
                Capsule()
                    .fill(HUDDesignTokens.Gradients.shimmerBeam)
                    .frame(width: beamWidth, height: 2.5)
                    .offset(x: phase * (width - beamWidth))
                    .shadow(color: HUDDesignTokens.Colors.processingViolet.opacity(0.65), radius: 3, y: 0)
            }
        }
        .frame(height: 2.5)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.3)
                .repeatForever(autoreverses: true)
            ) {
                phase = 1.0
            }
        }
    }
}
