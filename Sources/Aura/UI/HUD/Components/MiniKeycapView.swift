import SwiftUI

/// Authentic hardware keycap affordance mimicking Apple keyboard aesthetics.
public struct MiniKeycapView: View {
    public let label: String

    public init(_ label: String) {
        self.label = label
    }

    public var body: some View {
        Text(label)
            .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
            .foregroundColor(.white.opacity(0.70))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: HUDDesignTokens.Geometry.keycapCornerRadius, style: .continuous)
                    .fill(HUDDesignTokens.Gradients.keycapFace)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HUDDesignTokens.Geometry.keycapCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 1, y: 1)
    }
}
