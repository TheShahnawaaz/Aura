import XCTest
import SwiftUI
import AppKit
@testable import Aura

final class AppIconGeneratorTests: XCTestCase {
    @MainActor
    func testGenerateAppIconPNG() throws {
        let canvasSize: CGFloat = 1024
        let orbSize: CGFloat = canvasSize / 1.35 // 758.5 pt

        let iconView = ZStack {
            Color.clear
            LivingAuroraOrbView(
                overrideState: .idle,
                overrideAudioLevel: 0.0,
                size: orbSize,
                showSquircleBackground: true
            )
        }
        .frame(width: canvasSize, height: canvasSize)

        // Render using NSHostingView for robust bitmap capture
        let hostingView = NSHostingView(rootView: iconView)
        hostingView.frame = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
        hostingView.layoutSubtreeIfNeeded()

        // Wait a small run loop cycle for layout
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))

        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            XCTFail("Failed to allocate bitmapImageRep")
            return
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)

        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            XCTFail("Failed to encode PNG")
            return
        }

        // Write to temporary directory during unit test run
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_icon.png")
        try pngData.write(to: tempURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
        try? FileManager.default.removeItem(at: tempURL)
    }
}
