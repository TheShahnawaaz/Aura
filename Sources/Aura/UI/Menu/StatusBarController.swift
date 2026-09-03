import AppKit
import Combine
import SwiftUI

/// Manages Aura's presence in the macOS system status bar (Menu Bar Extra).
/// Allows reopening Settings, toggling voice, and quitting even when windows are closed.
@MainActor
public final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private let appState: AppState
    private let onToggleVoice: () -> Void
    private var cancellables = Set<AnyCancellable>()
    private var toggleMenuItem: NSMenuItem?

    public init(appState: AppState = .shared, onToggleVoice: @escaping () -> Void) {
        self.appState = appState
        self.onToggleVoice = onToggleVoice
        super.init()

        setupStatusItem()
        observeState()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Aura")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Aura Voice Assistant"
        }

        let menu = NSMenu()

        // 1. Settings item
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // 2. Toggle Voice item
        let toggleItem = NSMenuItem(
            title: "Toggle Voice (\(appState.hotkeyDisplayString))",
            action: #selector(toggleVoiceAction),
            keyEquivalent: ""
        )
        toggleItem.target = self
        self.toggleMenuItem = toggleItem
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // 3. About
        let aboutItem = NSMenuItem(
            title: "About Aura",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // 4. Quit
        let quitItem = NSMenuItem(
            title: "Quit Aura",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        self.statusItem = item
    }

    private func observeState() {
        appState.$hotkeyDisplayString
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hotkey in
                self?.toggleMenuItem?.title = "Toggle Voice (\(hotkey))"
            }
            .store(in: &cancellables)
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.showSettings()
    }

    @objc private func toggleVoiceAction() {
        onToggleVoice()
    }

    @objc private func openAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [
                NSApplication.AboutPanelOptionKey.applicationName: "Aura",
                NSApplication.AboutPanelOptionKey.version: "0.1.0"
            ]
        )
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
