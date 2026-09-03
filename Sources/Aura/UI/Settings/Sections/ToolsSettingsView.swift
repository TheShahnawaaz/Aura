import SwiftUI

/// Advanced configurator for Aura's native generic capabilities: computer, terminal, and mac_script.
public struct ToolsSettingsView: View {
    @ObservedObject private var capabilityConfig = CapabilityConfigManager.shared
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var testOutput: String? = nil

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerBar

            VStack(spacing: 16) {
                computerCard
                terminalCard
                macScriptCard
                webCard
                fileSystemCard
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
                    .font(.title3.weight(.bold))
                Text("\(capabilityConfig.activeToolCount) of 5 Capabilities Active")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            Text("Fine-grained control over Aura's macOS automation, web browsing, and workspace inspection capabilities.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 1. Computer Tool Card
    private var computerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: "macwindow.on.rectangle")
                    .font(.title2)
                    .foregroundColor(capabilityConfig.isComputerEnabled ? .blue : .secondary)
                    .frame(width: 36, height: 36)
                    .background((capabilityConfig.isComputerEnabled ? Color.blue : Color.secondary).opacity(0.12))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("computer")
                            .font(.headline)
                        Text("macOS UI Automation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Allows Aura to observe screen elements, click buttons, type text, and capture screenshots.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissible Sub-Actions")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

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
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(capabilityConfig.isComputerEnabled ? Color.blue.opacity(0.2) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - 2. Terminal Tool Card
    private var terminalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: "terminal.fill")
                    .font(.title2)
                    .foregroundColor(capabilityConfig.isTerminalEnabled ? .green : .secondary)
                    .frame(width: 36, height: 36)
                    .background((capabilityConfig.isTerminalEnabled ? Color.green : Color.secondary).opacity(0.12))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("terminal")
                            .font(.headline)
                        Text("Zsh Shell Execution")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Executes shell commands for development, inspections, and project workflows.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        .foregroundColor(.orange)
                    Text("Protected by GuardrailsEngine (rm, sudo, rmdir require confirmation)")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)

                Spacer()

                Button("Test Command") {
                    Task {
                        let res = try? await TerminalService.shared.execute(command: "echo 'Aura Terminal Active'")
                        withAnimation {
                            testOutput = res?.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            if let out = testOutput {
                Text(out)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(6)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(capabilityConfig.isTerminalEnabled ? Color.green.opacity(0.2) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - 3. Mac Script Tool Card
    private var macScriptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: "applescript.fill")
                    .font(.title2)
                    .foregroundColor(capabilityConfig.isMacScriptEnabled ? .purple : .secondary)
                    .frame(width: 36, height: 36)
                    .background((capabilityConfig.isMacScriptEnabled ? Color.purple : Color.secondary).opacity(0.12))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("mac_script")
                            .font(.headline)
                        Text("Apple Events Automation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Automates macOS apps (Notes, Music, Calendar, Safari, Finder) via native script bridges.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $capabilityConfig.isMacScriptEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            if capabilityConfig.isMacScriptEnabled {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissible Languages")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

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
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(capabilityConfig.isMacScriptEnabled ? Color.purple.opacity(0.2) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - 4. Web & Search Tools Card
    private var webCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundColor(capabilityConfig.isWebEnabled ? .blue : .secondary)
                    .frame(width: 36, height: 36)
                    .background((capabilityConfig.isWebEnabled ? Color.blue : Color.secondary).opacity(0.12))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("web_fetch & web_search")
                            .font(.headline)
                        Text("Online Browsing & API")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Fetches web pages, parses HTML content to clean markdown, and queries online search engines.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $capabilityConfig.isWebEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            if capabilityConfig.isWebEnabled {
                HStack(spacing: 8) {
                    Text("Includes: WebFetch (HTTP GET & JSON API) and WebSearch (DuckDuckGo search queries)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(capabilityConfig.isWebEnabled ? Color.blue.opacity(0.2) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - 5. File System & Code Tools Card
    private var fileSystemCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundColor(capabilityConfig.isFileSystemEnabled ? .indigo : .secondary)
                    .frame(width: 36, height: 36)
                    .background((capabilityConfig.isFileSystemEnabled ? Color.indigo : Color.secondary).opacity(0.12))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("workspace_files")
                            .font(.headline)
                        Text("Read, Edit & Search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Inspects files, performs fast regex searches via ripgrep patterns, and applies precision edits to documents.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $capabilityConfig.isFileSystemEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            if capabilityConfig.isFileSystemEnabled {
                HStack(spacing: 8) {
                    Text("Includes: Read, Write, Edit, Glob, and Grep tools")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(capabilityConfig.isFileSystemEnabled ? Color.indigo.opacity(0.2) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Sub-Action Toggle Helper
    private func subActionToggle(label: String, description: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption.weight(.medium))
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .toggleStyle(.checkbox)
    }

    private func permissionChip(title: String, granted: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(granted ? Color.green : Color.orange)
                .frame(width: 6, height: 6)
            Text("\(title): \(granted ? "Granted" : "Action Required")")
                .font(.caption2.weight(.medium))
                .foregroundColor(granted ? .green : .orange)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2.5)
        .background((granted ? Color.green : Color.orange).opacity(0.12))
        .cornerRadius(5)
    }
}
