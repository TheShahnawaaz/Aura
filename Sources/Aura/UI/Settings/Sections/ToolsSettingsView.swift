import SwiftUI

/// Advanced configurator for Aura's native generic capabilities: computer, terminal, and mac_script,
/// styled with the obsidian liquid-glass design system.
public struct ToolsSettingsView: View {
    @ObservedObject private var capabilityConfig = CapabilityConfigManager.shared
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var testOutput: String? = nil

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerBar

            VStack(spacing: 16) {
                thinkingEffortCard
                computerCard
                terminalCard
                macScriptCard
                webCard
                fileSystemCard
                visionCard
            }
        }
        .onAppear {
            permissionManager.refreshAll()
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("Native Capabilities")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text("\(capabilityConfig.activeToolCount) of 6 Active")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(ControlCenterTokens.Colors.accentIndigo.opacity(0.25))
                    .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                    .cornerRadius(4)
            }
            Text("Fine-grained control over Aura's macOS automation, web browsing, and workspace inspection capabilities.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.55))
        }
    }

    // MARK: - Thinking Effort Card
    private var thinkingEffortCard: some View {
        ControlCenterGlassCard {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(ControlCenterTokens.Colors.accentPurple.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundColor(ControlCenterTokens.Colors.accentPurple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Agent Reasoning & Deliberation")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Sets the depth of adaptive thinking and self-criticism before executing tools.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Picker("", selection: $capabilityConfig.thinkingEffort) {
                    Text("Low").tag("low")
                    Text("Medium (Recommended)").tag("medium")
                    Text("High").tag("high")
                }
                .pickerStyle(.menu)
                .frame(width: 190)
            }
        }
    }

    // MARK: - 1. Computer Tool Card
    private var computerCard: some View {
        ControlCenterGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill((capabilityConfig.isComputerEnabled ? ControlCenterTokens.Colors.accentIndigo : Color.white).opacity(0.12))
                            .frame(width: 32, height: 32)

                        Image(systemName: "macwindow.on.rectangle")
                            .font(.system(size: 14))
                            .foregroundColor(capabilityConfig.isComputerEnabled ? ControlCenterTokens.Colors.accentIndigo : .white.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("computer")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("macOS UI Automation")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Text("Allows Aura to observe screen elements, click buttons, type text, and capture screenshots.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Spacer()

                    Toggle("", isOn: $capabilityConfig.isComputerEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                // Permissions Status Strip
                HStack(spacing: 8) {
                    permissionChip(
                        title: "Accessibility",
                        granted: permissionManager.accessibilityStatus == .granted
                    )
                    permissionChip(
                        title: "Screen Recording",
                        granted: permissionManager.screenRecordingStatus == .granted
                    )
                }

                if capabilityConfig.isComputerEnabled {
                    Divider()
                        .overlay(Color.white.opacity(0.06))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Permissible Sub-Actions")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))

                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
                            GridRow {
                                subActionToggle(
                                    label: "Observe UI Elements",
                                    description: "Read screen hierarchy tree",
                                    isOn: $capabilityConfig.allowObserve
                                )
                                subActionToggle(
                                    label: "Click & Text Input",
                                    description: "Press buttons, type in fields",
                                    isOn: $capabilityConfig.allowClickAndType
                                )
                            }
                            GridRow {
                                subActionToggle(
                                    label: "Keyboard Shortcuts",
                                    description: "Press modifier combinations",
                                    isOn: $capabilityConfig.allowShortcuts
                                )
                                subActionToggle(
                                    label: "Capture Screenshots",
                                    description: "Take visual screen grabs",
                                    isOn: $capabilityConfig.allowScreenshots
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 2. Terminal Tool Card
    private var terminalCard: some View {
        ControlCenterGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill((capabilityConfig.isTerminalEnabled ? ControlCenterTokens.Colors.accentEmerald : Color.white).opacity(0.12))
                            .frame(width: 32, height: 32)

                        Image(systemName: "terminal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(capabilityConfig.isTerminalEnabled ? ControlCenterTokens.Colors.accentEmerald : .white.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("terminal")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Zsh Shell Execution")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Text("Executes shell commands for development, inspections, and project workflows.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Spacer()

                    Toggle("", isOn: $capabilityConfig.isTerminalEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                // Security Badge
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(ControlCenterTokens.Colors.accentAmber)
                        Text("Protected by GuardrailsEngine (rm, sudo, rmdir require confirmation)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ControlCenterTokens.Colors.accentAmber.opacity(0.15))
                    .cornerRadius(5)

                    Spacer()

                    Button {
                        Task {
                            let res = try? await TerminalService.shared.execute(command: "echo 'Aura Terminal Active'")
                            withAnimation {
                                testOutput = res?.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        }
                    } label: {
                        Text("Test Command")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }

                if let out = testOutput {
                    Text(out)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(8)
                        .background(ControlCenterTokens.Colors.sunkenSurface)
                        .cornerRadius(6)
                }
            }
        }
    }

    // MARK: - 3. Mac Script Tool Card
    private var macScriptCard: some View {
        ControlCenterGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill((capabilityConfig.isMacScriptEnabled ? ControlCenterTokens.Colors.accentPurple : Color.white).opacity(0.12))
                            .frame(width: 32, height: 32)

                        Image(systemName: "applescript.fill")
                            .font(.system(size: 14))
                            .foregroundColor(capabilityConfig.isMacScriptEnabled ? ControlCenterTokens.Colors.accentPurple : .white.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("mac_script")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Apple Events Automation")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Text("Automates macOS apps (Notes, Music, Calendar, Safari, Finder) via native script bridges.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Spacer()

                    Toggle("", isOn: $capabilityConfig.isMacScriptEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if capabilityConfig.isMacScriptEnabled {
                    Divider()
                        .overlay(Color.white.opacity(0.06))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Permissible Languages")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))

                        HStack(spacing: 24) {
                            subActionToggle(
                                label: "AppleScript",
                                description: "In-process NSAppleScript execution",
                                isOn: $capabilityConfig.allowAppleScript
                            )
                            subActionToggle(
                                label: "JavaScript (JXA)",
                                description: "JavaScript for Automation via stdin",
                                isOn: $capabilityConfig.allowJXA
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - 4. Web & Search Tools Card
    private var webCard: some View {
        ControlCenterGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill((capabilityConfig.isWebEnabled ? ControlCenterTokens.Colors.accentCyan : Color.white).opacity(0.12))
                            .frame(width: 32, height: 32)

                        Image(systemName: "globe")
                            .font(.system(size: 14))
                            .foregroundColor(capabilityConfig.isWebEnabled ? ControlCenterTokens.Colors.accentCyan : .white.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("web_fetch & web_search")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Online Browsing & API")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Text("Fetches web pages, parses HTML content to clean markdown, and queries online search engines.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Spacer()

                    Toggle("", isOn: $capabilityConfig.isWebEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if capabilityConfig.isWebEnabled {
                    Text("Includes: WebFetch (HTTP GET & JSON API) and WebSearch (DuckDuckGo search queries)")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
    }

    // MARK: - 5. File System & Code Tools Card
    private var fileSystemCard: some View {
        ControlCenterGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill((capabilityConfig.isFileSystemEnabled ? ControlCenterTokens.Colors.accentIndigo : Color.white).opacity(0.12))
                            .frame(width: 32, height: 32)

                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(capabilityConfig.isFileSystemEnabled ? ControlCenterTokens.Colors.accentIndigo : .white.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("workspace_files")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Read, Edit & Search")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Text("Inspects files, performs fast regex searches via ripgrep patterns, and applies precision edits to documents.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Spacer()

                    Toggle("", isOn: $capabilityConfig.isFileSystemEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if capabilityConfig.isFileSystemEnabled {
                    Text("Includes: Read, Write, Edit, Glob, and Grep tools")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
    }

    // MARK: - 6. Vision Card
    private var visionCard: some View {
        ControlCenterGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill((capabilityConfig.isVisionEnabled ? ControlCenterTokens.Colors.accentCyan : Color.white).opacity(0.12))
                            .frame(width: 32, height: 32)

                        Image(systemName: "eye.fill")
                            .font(.system(size: 14))
                            .foregroundColor(capabilityConfig.isVisionEnabled ? ControlCenterTokens.Colors.accentCyan : .white.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("view_image & vision")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Multimodal Image Understanding")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Text("Enables visual multimodal understanding. Allows Aura to inspect images on disk (PNG, JPEG, WebP) and see screen pixels directly during screenshots.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Spacer()

                    Toggle("", isOn: $capabilityConfig.isVisionEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if capabilityConfig.isVisionEnabled {
                    Text("Includes: view_image (local file visual inspection) and computer(screenshot) visual pixel streaming")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
    }

    // MARK: - Helpers
    private func subActionToggle(label: String, description: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .toggleStyle(.checkbox)
    }

    private func permissionChip(title: String, granted: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(granted ? ControlCenterTokens.Colors.accentEmerald : ControlCenterTokens.Colors.accentAmber)
                .frame(width: 5, height: 5)
            Text("\(title): \(granted ? "Granted" : "Action Required")")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(granted ? ControlCenterTokens.Colors.accentEmerald : ControlCenterTokens.Colors.accentAmber)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background((granted ? ControlCenterTokens.Colors.accentEmerald : ControlCenterTokens.Colors.accentAmber).opacity(0.12))
        .cornerRadius(4)
    }
}
