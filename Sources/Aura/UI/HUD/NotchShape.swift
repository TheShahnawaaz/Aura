import SwiftUI

/// SwiftUI Shape mimicking the MacBook notch silhouette:
/// Features subtle concave reverse fillets (ears) at the top corners that flare
/// outward to meet the display bezel, with rounded bottom corners.
public struct NotchShape: Shape {
    public var topEarRadius: CGFloat
    public var bottomCornerRadius: CGFloat

    public init(topEarRadius: CGFloat = 6, bottomCornerRadius: CGFloat = 14) {
        self.topEarRadius = topEarRadius
        self.bottomCornerRadius = bottomCornerRadius
    }

    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topEarRadius, bottomCornerRadius) }
        set {
            topEarRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = topEarRadius
        let br = bottomCornerRadius
        let k: CGFloat = 0.55228475 // Cubic Bezier constant for circle approximation

        // 1. Start top-left ear outer tip (tangent to top bezel)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // 2. Top-left concave fillet (ear) curving down into notch wall
        path.addCurve(
            to: CGPoint(x: rect.minX + r, y: rect.minY + r),
            control1: CGPoint(x: rect.minX + r * k, y: rect.minY),
            control2: CGPoint(x: rect.minX + r, y: rect.minY + r * (1.0 - k))
        )

        // 3. Left edge down to bottom curve start
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY - br))

        // 4. Bottom-left convex corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + r + br, y: rect.maxY),
            control: CGPoint(x: rect.minX + r, y: rect.maxY)
        )

        // 5. Bottom horizontal edge
        path.addLine(to: CGPoint(x: rect.maxX - r - br, y: rect.maxY))

        // 6. Bottom-right convex corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY - br),
            control: CGPoint(x: rect.maxX - r, y: rect.maxY)
        )

        // 7. Right edge up to top-right ear start
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY + r))

        // 8. Top-right concave fillet (ear) curving up to meet top bezel
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control1: CGPoint(x: rect.maxX - r, y: rect.minY + r * (1.0 - k)),
            control2: CGPoint(x: rect.maxX - r * k, y: rect.minY)
        )

        // 9. Close top edge flush with bezel
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()

        return path
    }
}

/// Strokes ONLY the notch silhouette:
/// Top-left ear fillet, left wall, bottom corners, bottom wall, right wall, and top-right ear fillet.
/// Leaves the flat top edge completely open without stroke so it seamlessly merges with the display bezel.
public struct NotchBorderShape: Shape {
    public var topEarRadius: CGFloat
    public var bottomCornerRadius: CGFloat

    public init(topEarRadius: CGFloat = 6, bottomCornerRadius: CGFloat = 14) {
        self.topEarRadius = topEarRadius
        self.bottomCornerRadius = bottomCornerRadius
    }

    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topEarRadius, bottomCornerRadius) }
        set {
            topEarRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = topEarRadius
        let br = bottomCornerRadius
        let k: CGFloat = 0.55228475

        // Start at top-left ear outer tip
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Top-left concave fillet (ear)
        path.addCurve(
            to: CGPoint(x: rect.minX + r, y: rect.minY + r),
            control1: CGPoint(x: rect.minX + r * k, y: rect.minY),
            control2: CGPoint(x: rect.minX + r, y: rect.minY + r * (1.0 - k))
        )

        // Left edge down
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY - br))

        // Bottom-left curve
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + r + br, y: rect.maxY),
            control: CGPoint(x: rect.minX + r, y: rect.maxY)
        )

        // Bottom horizontal edge
        path.addLine(to: CGPoint(x: rect.maxX - r - br, y: rect.maxY))

        // Bottom-right curve
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY - br),
            control: CGPoint(x: rect.maxX - r, y: rect.maxY)
        )

        // Right edge up
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY + r))

        // Top-right concave fillet (ear)
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control1: CGPoint(x: rect.maxX - r, y: rect.minY + r * (1.0 - k)),
            control2: CGPoint(x: rect.maxX - r * k, y: rect.minY)
        )

        return path
    }
}
