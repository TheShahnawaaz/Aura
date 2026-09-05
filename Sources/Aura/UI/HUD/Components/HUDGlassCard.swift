import SwiftUI

/// Reusable sculpted obsidian glass card container for HUD live cards and inspector modules.
public struct HUDGlassCard<Content: View>: View {
    private let content: Content
    private let paddingHorizontal: CGFloat
    private let paddingVertical: CGFloat

    public init(
        paddingHorizontal: CGFloat = 12,
        paddingVertical: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.paddingHorizontal = paddingHorizontal
        self.paddingVertical = paddingVertical
    }

    public var body: some View {
        content
            .padding(.horizontal, paddingHorizontal)
            .padding(.vertical, paddingVertical)
            .background(
                RoundedRectangle(cornerRadius: HUDDesignTokens.Geometry.cardCornerRadius, style: .continuous)
                    .fill(HUDDesignTokens.Colors.glassCardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HUDDesignTokens.Geometry.cardCornerRadius, style: .continuous)
                    .stroke(HUDDesignTokens.Gradients.cardBorder, lineWidth: 0.75)
            )
    }
}
