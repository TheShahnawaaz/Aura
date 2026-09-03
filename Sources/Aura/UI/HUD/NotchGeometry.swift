import AppKit
import SwiftUI
import Combine

/// Calculates screen and hardware notch dimensions using public AppKit safe-area APIs.
@MainActor
public final class NotchGeometry: ObservableObject {
    @Published public var notchWidth: CGFloat = fallbackPillWidth
    @Published public var notchHeight: CGFloat = fallbackPillHeight
    @Published public var notchCenterX: CGFloat = 0
    @Published public var hasNotch: Bool = false
    @Published public var screenFrame: CGRect = .zero

    public static let fallbackPillWidth: CGFloat = 200
    public static let fallbackPillHeight: CGFloat = 32

    public init(for screen: NSScreen? = NSScreen.main) {
        if let screen {
            update(for: screen)
        } else {
            hasNotch = false
            notchWidth = Self.fallbackPillWidth
            notchHeight = Self.fallbackPillHeight
            notchCenterX = 0
            screenFrame = .zero
        }
    }

    public func update(for screen: NSScreen) {
        screenFrame = screen.frame
        let topInset = screen.safeAreaInsets.top
        hasNotch = topInset > 0

        if hasNotch,
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let notchMinX = left.maxX
            let notchMaxX = right.minX
            notchWidth = max(0, notchMaxX - notchMinX)
            notchHeight = topInset
            notchCenterX = (notchMinX + notchMaxX) / 2.0
        } else {
            // External monitor or Mac without hardware notch: display as a floating pill
            notchWidth = Self.fallbackPillWidth
            notchHeight = Self.fallbackPillHeight
            notchCenterX = screen.frame.midX
        }
    }

    /// Standard ear width beside the physical notch (provides ample room for dot and labels without wrapping)
    public var earWidth: CGFloat {
        hasNotch ? 85 : 50
    }

    /// Fixed width for the top notch cap bar
    public var capBarWidth: CGFloat {
        notchWidth + (earWidth * 2)
    }

    /// Computes the fixed, constant width for the HUD across all states.
    public var closedWidth: CGFloat {
        capBarWidth
    }
}
