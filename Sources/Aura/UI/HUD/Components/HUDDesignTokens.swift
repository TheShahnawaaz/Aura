import SwiftUI

/// Centralized design tokens for the Aura Notch HUD, establishing a unified
/// obsidian liquid-glass visual identity across all components.
public enum HUDDesignTokens {

    // MARK: - Colors
    public enum Colors {
        /// True pitch black (#000000) matching Apple's hardware notch and iPhone Dynamic Island
        public static let notchBlack = Color.black

        /// Deep obsidian space base color for the notch container when expanded
        public static let obsidianBase = Color(red: 0.035, green: 0.038, blue: 0.046)

        /// Semi-transparent dark surface fill for elevated glass cards
        public static let glassCardFill = Color(red: 0.10, green: 0.10, blue: 0.13).opacity(0.55)

        /// Faint ambient border highlight for glass surfaces
        public static let glassBorderTop = Color.white.opacity(0.16)
        public static let glassBorderBottom = Color.white.opacity(0.04)

        // State Harmonious Accent Colors (matched with LivingAuroraTheme)
        public static let idleLilac = Color(red: 0.35, green: 0.40, blue: 0.88)
        public static let listeningCyan = Color(red: 0.00, green: 0.95, blue: 0.92)
        public static let listeningMint = Color(red: 0.20, green: 0.98, blue: 0.75)
        public static let processingViolet = Color(red: 0.65, green: 0.15, blue: 0.98)
        public static let processingCyan = Color(red: 0.20, green: 0.80, blue: 1.00)
        public static let processingOrchid = Color(red: 0.88, green: 0.25, blue: 0.92)
        public static let speakingCoral = Color(red: 1.00, green: 0.44, blue: 0.54)
        public static let speakingPeach = Color(red: 1.00, green: 0.72, blue: 0.55)
        public static let emeraldSuccess = Color(red: 0.25, green: 0.95, blue: 0.55)
        public static let actionAmber = Color.orange
        public static let errorRed = Color.red
    }

    // MARK: - Gradients
    public enum Gradients {
        /// Outer notch specular border gradient (subtle highlight when expanded, crisp prominent contour rim when resting)
        public static func notchBorder(isExpanded: Bool) -> LinearGradient {
            if isExpanded {
                return LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.24),
                        Color.white.opacity(0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color.white.opacity(0.65),
                        Color.white.opacity(0.48),
                        Color.white.opacity(0.28)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }

        /// Inner glass card specular edge gradient
        public static let cardBorder = LinearGradient(
            colors: [
                Colors.glassBorderTop,
                Colors.glassBorderBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Listening audio-reactive waveform gradient
        public static let listeningWave = LinearGradient(
            colors: [Colors.listeningCyan, Colors.listeningMint],
            startPoint: .bottom,
            endPoint: .top
        )

        /// Speaking vocal equalizer gradient
        public static let speakingWave = LinearGradient(
            colors: [Colors.speakingCoral, Colors.speakingPeach],
            startPoint: .bottom,
            endPoint: .top
        )

        /// Reasoning shimmer progress beam gradient
        public static let shimmerBeam = LinearGradient(
            colors: [
                Colors.processingViolet,
                Colors.processingCyan,
                Colors.processingOrchid,
                Colors.processingCyan
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        /// Approve button tactile gradient
        public static let approveButton = LinearGradient(
            colors: [Color.green.opacity(0.85), Color.green.opacity(0.70)],
            startPoint: .top,
            endPoint: .bottom
        )

        /// Keycap face gradient
        public static let keycapFace = LinearGradient(
            colors: [
                Color.white.opacity(0.13),
                Color.white.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Spring Physics Animations (matching Framer Motion standards)
    public enum Springs {
        /// Primary layout and state morphing spring (stiffness: ~350, damping: ~28)
        public static let fluid = Animation.spring(response: 0.36, dampingFraction: 0.82)

        /// Snappy micro-interaction spring for clicks, keycaps, and copy feedback
        public static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.70)

        /// Audio reactivity spring for rapid frequency changes
        public static let audioReact = Animation.spring(response: 0.15, dampingFraction: 0.65)
    }

    // MARK: - Geometry & Radii
    public enum Geometry {
        public static let minExpandedWidth: CGFloat = 520
        public static let closedEarRadius: CGFloat = 6
        public static let expandedBottomCornerRadius: CGFloat = 20
        public static let closedBottomCornerRadius: CGFloat = 14
        public static let cardCornerRadius: CGFloat = 11
        public static let keycapCornerRadius: CGFloat = 3.5
        public static let toolCardCornerRadius: CGFloat = 8
    }
}
