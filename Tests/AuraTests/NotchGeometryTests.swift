import XCTest
@testable import Aura

@MainActor
final class NotchGeometryTests: XCTestCase {
    func testFallbackPillGeometry() {
        let geometry = NotchGeometry(for: nil)

        XCTAssertFalse(geometry.hasNotch)
        XCTAssertEqual(geometry.notchWidth, NotchGeometry.fallbackPillWidth)
        XCTAssertEqual(geometry.notchHeight, NotchGeometry.fallbackPillHeight)
        XCTAssertGreaterThan(geometry.closedWidth, NotchGeometry.fallbackPillWidth)
    }
}
