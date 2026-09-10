import SwiftUI

/// Unified design tokens for the Aura Control Center window, harmonized with the Notch HUD
/// to produce a luxurious, obsidian liquid-glass desktop experience.
public enum ControlCenterTokens {

    // MARK: - Colors
    public enum Colors {
        /// Primary deep space obsidian background
        public static let windowBackdrop = Color(red: 0.035, green: 0.038, blue: 0.046)

        /// Sidebar background tone
        public static let sidebarBackdrop = Color(red: 0.045, green: 0.048, blue: 0.058).opacity(0.88)

        /// Translucent elevated glass card fill
        public static let glassSurface = Color(red: 0.10, green: 0.105, blue: 0.14).opacity(0.58)

        /// Deep sunken background for code blocks, inputs, and terminals
        public static let sunkenSurface = Color(red: 0.02, green: 0.025, blue: 0.035).opacity(0.75)

        /// Soft border highlights
        public static let borderSpecular = Color.white.opacity(0.12)
        public static let borderFaint = Color.white.opacity(0.04)

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
                Color.white.opacity(0.16),
                Color.white.opacity(0.05),
                Color.white.opacity(0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Active sidebar capsule glow
        public static func activeCapsuleGlow(color: Color) -> LinearGradient {
            LinearGradient(
                colors: [
                    color.opacity(0.24),
                    color.opacity(0.08)
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
        public static let fluid = Animation.spring(response: 0.36, dampingFraction: 0.82)

        /// Snappy responsive hover & button interactions
        public static let snappy = Animation.spring(response: 0.22, dampingFraction: 0.72)

        /// Micro-bounce for tactile feedback
        public static let microBounce = Animation.spring(response: 0.15, dampingFraction: 0.65)
    }

    // MARK: - Metrics & Radii
    public enum Radii {
        public static let card: CGFloat = 13
        public static let innerCard: CGFloat = 9
        public static let capsule: CGFloat = 8
        public static let keycap: CGFloat = 5
        public static let button: CGFloat = 7
    }
}
