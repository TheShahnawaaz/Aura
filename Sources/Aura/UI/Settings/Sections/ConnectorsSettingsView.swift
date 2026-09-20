import SwiftUI

/// Modern Connectors & Model Context Protocol (MCP) server manager for Aura,
/// styled with the obsidian liquid-glass design system.
public struct ConnectorsSettingsView: View {
    @State private var servers: [MCPServerConfig] = []
    @State private var isShowingAddServerSheet = false
    @State private var selectedPreset: QuickConnectorPreset? = nil
    @State private var presetInputValue = ""
    @State private var statusToast: String? = nil

    // Custom Server Form
    @State private var customName = ""
    @State private var customCommand = "npx"
    @State private var customArgs = ""
    @State private var customEnv = ""

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerBar

            if let toast = statusToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                    Text(toast)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(10)
                .background(ControlCenterTokens.Colors.accentEmerald.opacity(0.18))
                .cornerRadius(8)
                .transition(.opacity)
            }

            // Quick Connectors Section
            quickConnectorsSection

            Divider()
                .overlay(Color.white.opacity(0.06))

            // Active MCP Servers Table
            activeServersSection
        }
        .onAppear {
            loadServers()
        }
        .sheet(isPresented: $isShowingAddServerSheet) {
            addCustomServerSheet
        }
        .sheet(item: $selectedPreset) { preset in
            presetConfigurationSheet(for: preset)
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Model Context Protocol (MCP)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(servers.filter { $0.isEnabled }.count) Active")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(ControlCenterTokens.Colors.accentIndigo.opacity(0.25))
                        .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                        .cornerRadius(4)
                }
                Text("Connect external tools, databases, APIs, and cloud services directly to Aura's agent runtime.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Button {
                customName = ""
                customCommand = "npx"
                customArgs = ""
                customEnv = ""
                isShowingAddServerSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Add Custom Server")
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ControlCenterTokens.Colors.accentIndigo)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Quick Connectors Section
    private var quickConnectorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Connectors & Presets")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QuickConnectorPreset.allCases) { preset in
                        presetCard(for: preset)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func presetCard(for preset: QuickConnectorPreset) -> some View {
        let isInstalled = servers.contains { $0.name == preset.serverName }

        return ControlCenterGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(preset.color.opacity(0.2))
                            .frame(width: 28, height: 28)

                        Image(systemName: preset.iconName)
                            .font(.system(size: 13))
                            .foregroundColor(preset.color)
                    }

                    Spacer()

                    if isInstalled {
                        Text("Installed")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(ControlCenterTokens.Colors.accentEmerald.opacity(0.2))
                            .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                            .cornerRadius(4)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text(preset.subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }

                Spacer(minLength: 4)

                Button {
                    if !isInstalled {
                        if preset.requiresInput {
                            presetInputValue = ""
                            selectedPreset = preset
                        } else {
                            installPresetDirectly(preset)
                        }
                    }
                } label: {
                    Text(isInstalled ? "Configured" : "Add Connector")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(isInstalled ? Color.white.opacity(0.06) : ControlCenterTokens.Colors.accentIndigo.opacity(0.3))
                        .foregroundColor(isInstalled ? .white.opacity(0.4) : .white)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .disabled(isInstalled)
            }
        }
        .frame(width: 175, height: 145)
    }

    // MARK: - Active Servers Section
    private var activeServersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configured MCP Servers (\(servers.count))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            if servers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.4))
                    Text("No MCP Servers Configured")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    Text("Click on a popular connector above or add a custom stdio command to expand Aura's tools.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(ControlCenterTokens.Colors.glassSurface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(servers) { server in
                        serverRow(for: server)
                    }
                }
            }
        }
    }

    private func serverRow(for server: MCPServerConfig) -> some View {
        ControlCenterGlassCard {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill((server.isEnabled ? ControlCenterTokens.Colors.accentIndigo : Color.white).opacity(0.12))
                        .frame(width: 28, height: 28)

                    Image(systemName: "terminal")
                        .font(.system(size: 12))
                        .foregroundColor(server.isEnabled ? ControlCenterTokens.Colors.accentIndigo : .white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(server.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text(server.command)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(ControlCenterTokens.Colors.accentCyan)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(ControlCenterTokens.Colors.accentCyan.opacity(0.15))
                            .cornerRadius(3)
                    }

                    if !server.args.isEmpty {
                        Text(server.args.joined(separator: " "))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { server.isEnabled },
                    set: { _ in
                        Task {
                            await MCPManager.shared.toggleServer(name: server.name)
                            loadServers()
                        }
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)

                Button {
                    Task {
                        await MCPManager.shared.remove(serverName: server.name)
                        loadServers()
                        showToast("Removed '\(server.name)'")
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(Color.red.opacity(0.8))
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Sheets
    private var addCustomServerSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Add Custom MCP Server")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button("Cancel") { isShowingAddServerSheet = false }
                    .buttonStyle(.plain)
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 12))
            }

            VStack(alignment: .leading, spacing: 12) {
                customField("Server Name", placeholder: "e.g. my-local-service", text: $customName)
                customField("Executable Command", placeholder: "e.g. npx, python3, uvx, node", text: $customCommand)
                customField("Arguments (space separated)", placeholder: "e.g. -y @modelcontextprotocol/server-github", text: $customArgs)
                customField("Environment Variables (KEY=VALUE, comma separated)", placeholder: "e.g. API_KEY=abc123xyz, DEBUG=1", text: $customEnv)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Add Server") {
                    let cleanName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleanName.isEmpty else { return }

                    let args = customArgs.split(separator: " ").map(String.init)
                    var env: [String: String] = [:]
                    for pair in customEnv.split(separator: ",") {
                        let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                        if parts.count == 2 {
                            env[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
                        }
                    }

                    let server = MCPServerConfig(
                        name: cleanName,
                        command: customCommand.trimmingCharacters(in: .whitespacesAndNewlines),
                        args: args,
                        env: env,
                        isEnabled: true
                    )

                    Task {
                        await MCPManager.shared.register(server: server)
                        loadServers()
                        isShowingAddServerSheet = false
                        showToast("Added '\(server.name)' successfully")
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(ControlCenterTokens.Colors.accentIndigo)
                .foregroundColor(.white)
                .cornerRadius(6)
                .buttonStyle(.plain)
                .disabled(customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .background(ControlCenterTokens.Colors.windowBackdrop)
        .frame(width: 480, height: 380)
    }

    private func customField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(8)
                .background(ControlCenterTokens.Colors.sunkenSurface)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }

    private func presetConfigurationSheet(for preset: QuickConnectorPreset) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(preset.title, systemImage: preset.iconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(preset.color)
                Spacer()
                Button("Cancel") { selectedPreset = nil }
                    .buttonStyle(.plain)
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 12))
            }

            Text(preset.instructions)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.65))

            VStack(alignment: .leading, spacing: 4) {
                Text(preset.inputLabel.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))

                TextField(preset.inputPlaceholder, text: $presetInputValue)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(ControlCenterTokens.Colors.sunkenSurface)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }

            Spacer()

            HStack {
                Spacer()
                Button("Install Connector") {
                    installPresetWithInput(preset, input: presetInputValue)
                    selectedPreset = nil
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(ControlCenterTokens.Colors.accentIndigo)
                .foregroundColor(.white)
                .cornerRadius(6)
                .buttonStyle(.plain)
                .disabled(presetInputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .background(ControlCenterTokens.Colors.windowBackdrop)
        .frame(width: 460, height: 280)
    }

    // MARK: - Actions
    private func loadServers() {
        Task {
            let list = await MCPManager.shared.listServers()
            await MainActor.run {
                self.servers = list
            }
        }
    }

    private func installPresetDirectly(_ preset: QuickConnectorPreset) {
        let server = MCPServerConfig(
            name: preset.serverName,
            command: preset.defaultCommand,
            args: preset.defaultArgs,
            env: preset.defaultEnv,
            isEnabled: true
        )
        Task {
            await MCPManager.shared.register(server: server)
            loadServers()
            showToast("Added '\(preset.title)' connector")
        }
    }

    private func installPresetWithInput(_ preset: QuickConnectorPreset, input: String) {
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        var server: MCPServerConfig

        switch preset {
        case .github:
            server = MCPServerConfig(
                name: "github",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-github"],
                env: ["GITHUB_PERSONAL_ACCESS_TOKEN": cleanInput],
                isEnabled: true
            )
        case .fetch:
            server = MCPServerConfig(
                name: "fetch",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-fetch"],
                env: [:],
                isEnabled: true
            )
        }

        Task {
            await MCPManager.shared.register(server: server)
            loadServers()
            showToast("Configured '\(preset.title)' connector")
        }
    }

    private func showToast(_ message: String) {
        withAnimation { statusToast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { statusToast = nil }
        }
    }
}

// MARK: - Presets Definition
enum QuickConnectorPreset: String, CaseIterable, Identifiable {
    case github = "GitHub"
    case fetch = "Web Fetch"

    var id: String { rawValue }
    var title: String { rawValue }

    var serverName: String {
        switch self {
        case .github: return "github"
        case .fetch: return "fetch"
        }
    }

    var subtitle: String {
        switch self {
        case .github: return "Inspect repos, pull requests, issues"
        case .fetch: return "Fetch & convert web pages to markdown"
        }
    }

    var iconName: String {
        switch self {
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .fetch: return "globe"
        }
    }

    var color: Color {
        switch self {
        case .github: return .gray
        case .fetch: return .blue
        }
    }

    var requiresInput: Bool {
        self != .fetch
    }

    var instructions: String {
        switch self {
        case .github: return "Enter your GitHub Personal Access Token (classic or fine-grained with repo scope)."
        case .fetch: return "Installs @modelcontextprotocol/server-fetch instantly."
        }
    }

    var inputLabel: String {
        switch self {
        case .github: return "GitHub Access Token"
        case .fetch: return ""
        }
    }

    var inputPlaceholder: String {
        switch self {
        case .github: return "ghp_..."
        case .fetch: return ""
        }
    }

    var defaultCommand: String {
        "npx"
    }

    var defaultArgs: [String] {
        switch self {
        case .fetch: return ["-y", "@modelcontextprotocol/server-fetch"]
        default: return []
        }
    }

    var defaultEnv: [String: String] {
        [:]
    }
}
