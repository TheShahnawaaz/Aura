import SwiftUI

/// Main application entry point for Aura.
/// Delegates window lifecycle and background persistence to AppDelegate.
@main
struct AuraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Aura") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "Aura",
                            NSApplication.AboutPanelOptionKey.version: "0.1.0"
                        ]
                    )
                }
            }

            CommandMenu("Aura") {
                Button("Toggle Voice Listening (\(appState.hotkeyDisplayString))") {
                    appDelegate.handleHotKeyToggle()
                }
                .keyboardShortcut(" ", modifiers: .option)

                Divider()

                Button("Settings...") {
                    SettingsWindowController.shared.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
