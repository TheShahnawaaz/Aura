import SwiftUI

/// Unified design tokens for the Aura Control Center window, harmonized with the Notch HUD
/// to produce a luxurious, obsidian liquid-glass desktop experience.
public enum ControlCenterTokens {

    // MARK: - Colors
    public enum Colors {
        /// Primary deep space obsidian background
        public static let windowBackdrop = Color(red: 0.035, green: 0.038, blue: 0.046)

        /// Sidebar background tone with Apple Vibrancy blend
        public static let sidebarBackdrop = Color(red: 0.042, green: 0.045, blue: 0.054).opacity(0.92)

        /// Translucent elevated glass card fill
        public static let glassSurface = Color(red: 0.09, green: 0.095, blue: 0.125).opacity(0.62)

        /// Deep sunken background for code blocks, inputs, and terminals
        public static let sunkenSurface = Color(red: 0.018, green: 0.020, blue: 0.028).opacity(0.85)

        /// Soft border highlights
        public static let borderSpecular = Color.white.opacity(0.12)
        public static let borderFaint = Color.white.opacity(0.04)

        // Core Brand Accent — Aura Electric Iris / Aurora Violet
        public static let accentIris = Color(red: 0.48, green: 0.36, blue: 1.00)
        public static let accentIrisSoft = Color(red: 0.48, green: 0.36, blue: 1.00).opacity(0.18)

        // Semantic Accents
        public static let accentIndigo = Color(red: 0.38, green: 0.45, blue: 1.00)
        public static let accentCyan = Color(red: 0.00, green: 0.88, blue: 0.95)
        public static let accentPurple = Color(red: 0.68, green: 0.35, blue: 0.98)
        public static let accentEmerald = Color(red: 0.22, green: 0.88, blue: 0.52)
        public static let accentAmber = Color(red: 1.00, green: 0.65, blue: 0.20)
        public static let accentCoral = Color(red: 1.00, green: 0.42, blue: 0.52)
    }

    // MARK: - Gradients
    public enum Gradients {
        /// Specular border stroke for elevated glass cards
        public static let specularBorder = LinearGradient(
            colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.04),
                Color.white.opacity(0.01)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Active sidebar capsule glow
        public static func activeCapsuleGlow(color: Color) -> LinearGradient {
            LinearGradient(
                colors: [
                    color.opacity(0.22),
                    color.opacity(0.06)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        /// User chat bubble gradient
        public static let userBubble = LinearGradient(
            colors: [
                Color(red: 0.28, green: 0.32, blue: 0.92).opacity(0.40),
                Color(red: 0.16, green: 0.22, blue: 0.65).opacity(0.28)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Keycap face gradient
        public static let keycapFace = LinearGradient(
            colors: [
                Color.white.opacity(0.11),
                Color.white.opacity(0.04)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Motion / Springs
    public enum Motion {
        /// Fluid layout transitions
        public static let fluid = Animation.spring(response: 0.34, dampingFraction: 0.82)

        /// Snappy responsive hover & button interactions
        public static let snappy = Animation.spring(response: 0.20, dampingFraction: 0.74)

        /// Micro-bounce for tactile feedback
        public static let microBounce = Animation.spring(response: 0.14, dampingFraction: 0.68)
    }

    // MARK: - Metrics & Radii
    public enum Radii {
        public static let card: CGFloat = 12
        public static let innerCard: CGFloat = 8
        public static let capsule: CGFloat = 7
        public static let keycap: CGFloat = 5
        public static let button: CGFloat = 6
    }

    // MARK: - Spacing Scale (8pt Grid)
    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let xxxl: CGFloat = 32
    }

    // MARK: - Stroke
    public enum Stroke {
        public static let hairline: CGFloat = 0.5
        public static let subtle: CGFloat = 1.0
        public static let focus: CGFloat = 1.5
    }
}
