import SwiftUI

/// Shortcuts and triggers configuration section styled with obsidian liquid-glass.
public struct ShortcutsSettingsView: View {
    @ObservedObject public var appState: AppState

    @AppStorage("selectedHotkey") private var selectedHotkey: String = HotkeyOption.optionSpace.rawValue
    @AppStorage("autoSubmitOnSilence") private var autoSubmitOnSilence: Bool = false
    @AppStorage("silenceDuration") private var silenceDuration: Double = 1.8

    public init(appState: AppState = .shared) {
        self.appState = appState
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Triggers & Shortcuts")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Configure system-wide hotkeys, voice activation triggers, and silence auto-submission.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                // Global Hotkey Card
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentEmerald.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "keyboard.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                            }

                            Text("Global System Hotkey")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            ControlCenterKeycapView(appState.hotkeyDisplayString, fontSize: 12)
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.06))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("KEYBOARD SHORTCUT")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.45))

                            Picker("", selection: $selectedHotkey) {
                                ForEach(HotkeyOption.allCases) { (opt: HotkeyOption) in
                                    Text(opt.displayName).tag(opt.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 320, alignment: .leading)
                            .onChange(of: selectedHotkey) { _, newValue in
                                if let option = HotkeyOption(rawValue: newValue) {
                                    HotkeyManager.shared.updateHotkey(option)
                                }
                            }
                        }

                        Text("Press this hotkey anywhere in macOS to trigger the Notch HUD. Press it again to submit your voice command or barge in while speaking.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }

                // Voice Submission Behavior Card
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentAmber.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "timer")
                                    .font(.system(size: 13))
                                    .foregroundColor(ControlCenterTokens.Colors.accentAmber)
                            }

                            Text("Voice Submission Behavior")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.06))

                        Toggle("Automatically submit when speech finishes (Silence Detection)", isOn: $autoSubmitOnSilence)
                            .toggleStyle(.switch)
                            .foregroundColor(.white.opacity(0.9))

                        if autoSubmitOnSilence {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("SILENCE THRESHOLD")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.45))
                                    Spacer()
                                    Text(String(format: "%.1f seconds", silenceDuration))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                Slider(value: $silenceDuration, in: 0.8...3.5, step: 0.1)
                            }

                            Text("Aura will automatically stop listening and send your prompt after detecting continuous silence.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
