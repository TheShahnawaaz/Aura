import SwiftUI

/// Shortcuts and triggers configuration section.
public struct ShortcutsSettingsView: View {
    @ObservedObject public var appState: AppState

    @AppStorage("selectedHotkey") private var selectedHotkey: String = HotkeyOption.optionSpace.rawValue
    @AppStorage("autoSubmitOnSilence") private var autoSubmitOnSilence: Bool = false
    @AppStorage("silenceDuration") private var silenceDuration: Double = 1.8

    public init(appState: AppState = .shared) {
        self.appState = appState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Triggers & Shortcuts")
                        .font(.title2.weight(.bold))
                    Text("Configure system-wide hotkeys, voice activation triggers, and silence auto-submission.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                hotkeyCard

                voiceBehaviorCard
            }
            .padding(24)
        }
    }

    // MARK: - Subviews
    private var hotkeyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Global Hotkey", systemImage: "keyboard")
                    .font(.headline)
                Spacer()
                Text(appState.hotkeyDisplayString)
                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Keyboard Shortcut")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $selectedHotkey) {
                    ForEach(HotkeyOption.allCases) { (opt: HotkeyOption) in
                        Text(opt.displayName).tag(opt.rawValue)
                    }
                }
                .onChange(of: selectedHotkey) { _, newValue in
                    if let option = HotkeyOption(rawValue: newValue) {
                        HotkeyManager.shared.updateHotkey(option)
                    }
                }
            }

            Text("Press this hotkey anywhere in macOS to trigger the Notch HUD. Press it again to submit your voice command or barge in while speaking.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var voiceBehaviorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Voice Submission Behavior", systemImage: "timer")
                .font(.headline)

            Divider()

            Toggle("Automatically submit when speech finishes (Silence Detection)", isOn: $autoSubmitOnSilence)
                .toggleStyle(.switch)

            if autoSubmitOnSilence {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Silence Threshold:")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f seconds", silenceDuration))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                    }
                    Slider(value: $silenceDuration, in: 1.0...3.5, step: 0.2)
                }
            } else {
                Text("Manual Mode: Press your hotkey to start speaking, and press it again when finished to submit.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
