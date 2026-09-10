import SwiftUI

/// Tactile, hardware-molded keycap renderer for keyboard shortcuts in Control Center.
public struct ControlCenterKeycapView: View {
    public let label: String
    public let fontSize: CGFloat

    public init(_ label: String, fontSize: CGFloat = 11) {
        self.label = label
        self.fontSize = fontSize
    }

    public var body: some View {
        Text(label)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background {
                ZStack {
                    // Under-shadow / base depth
                    RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.keycap, style: .continuous)
                        .fill(Color.black.opacity(0.6))
                        .offset(y: 1.5)

                    // Keycap surface
                    RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.keycap, style: .continuous)
                        .fill(ControlCenterTokens.Gradients.keycapFace)

                    // Specular rim
                    RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.keycap, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.24), Color.white.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                }
            }
            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}
