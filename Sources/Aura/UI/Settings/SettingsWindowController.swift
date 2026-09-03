import AppKit
import SwiftUI

/// Window controller that manages the Aura Control Center app independently from the Notch HUD.
/// Intercepts the window close action to hide the window without terminating the background app or overlay.
@MainActor
public final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    public static let shared = SettingsWindowController()

    private let appState: AppState

    public init(appState: AppState = .shared) {
        self.appState = appState

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 840, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Aura Control Center"
        window.minSize = NSSize(width: 760, height: 480)
        window.isReleasedWhenClosed = false
        window.center()

        let hostingView = NSHostingView(rootView: SettingsView(appState: appState))
        window.contentView = hostingView

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Brings the Settings window forward, activating the application.
    public func showSettings() {
        guard let window = self.window else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Opens the Control Center window and immediately selects the Chat tab.
    public func showChat() {
        self.appState.activeSidebarTab = .chat
        showSettings()
    }

    // MARK: - NSWindowDelegate
    /// When the user clicks the red "X" close button, hide the window instead of destroying it.
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
