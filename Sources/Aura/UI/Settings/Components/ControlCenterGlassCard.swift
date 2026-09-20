import SwiftUI

/// Elevated obsidian frosted glass card container for Control Center panels.
public struct ControlCenterGlassCard<Content: View>: View {
    public let cornerRadius: CGFloat
    public let content: () -> Content

    @State private var isHovered: Bool = false

    public init(
        cornerRadius: CGFloat = ControlCenterTokens.Radii.card,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    public var body: some View {
        content()
            .padding(16)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(ControlCenterTokens.Colors.glassSurface)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            isHovered
                                ? LinearGradient(
                                    colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : ControlCenterTokens.Gradients.specularBorder,
                            lineWidth: ControlCenterTokens.Stroke.hairline
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(isHovered ? 0.32 : 0.20),
                radius: isHovered ? 10 : 6,
                x: 0,
                y: isHovered ? 3 : 2
            )
            .offset(y: isHovered ? -0.5 : 0)
            .onHover { hovering in
                withAnimation(ControlCenterTokens.Motion.snappy) {
                    isHovered = hovering
                }
            }
    }
}

/// Convenience view modifier for applying obsidian glass card styling.
public struct ControlCenterGlassCardModifier: ViewModifier {
    public let cornerRadius: CGFloat

    public func body(content: Content) -> some View {
        ControlCenterGlassCard(cornerRadius: cornerRadius) {
            content
        }
    }
}

public extension View {
    func controlCenterGlassCard(cornerRadius: CGFloat = ControlCenterTokens.Radii.card) -> some View {
        self.modifier(ControlCenterGlassCardModifier(cornerRadius: cornerRadius))
    }
}
