import SwiftUI

/// Modern Connectors & Model Context Protocol (MCP) server manager for Aura.
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
                        .foregroundColor(.green)
                    Text(toast)
                        .font(.caption.weight(.medium))
                    Spacer()
                }
                .padding(10)
                .background(Color.green.opacity(0.12))
                .cornerRadius(8)
                .transition(.opacity)
            }

            // Quick Connectors Section
            quickConnectorsSection

            Divider()

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
                        .font(.title3.weight(.bold))
                    Text("\(servers.filter { $0.isEnabled }.count) Active")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                Text("Connect external tools, databases, APIs, and cloud services directly to Aura's agent runtime.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                customName = ""
                customCommand = "npx"
                customArgs = ""
                customEnv = ""
                isShowingAddServerSheet = true
            } label: {
                Label("Add Custom Server", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    // MARK: - Quick Connectors Section
    private var quickConnectorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Connectors & Presets")
                .font(.headline)

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

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: preset.iconName)
                    .font(.title3)
                    .foregroundColor(preset.color)
                    .frame(width: 32, height: 32)
                    .background(preset.color.opacity(0.12))
                    .cornerRadius(8)
                Spacer()
                if isInstalled {
                    Text("Installed")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(preset.title)
                    .font(.subheadline.weight(.semibold))
                Text(preset.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            Button(isInstalled ? "Configured" : "Add Connector") {
                if !isInstalled {
                    if preset.requiresInput {
                        presetInputValue = ""
                        selectedPreset = preset
                    } else {
                        installPresetDirectly(preset)
                    }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .disabled(isInstalled)
        }
        .padding(12)
        .frame(width: 170, height: 145, alignment: .topLeading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isInstalled ? Color.green.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Active Servers Section
    private var activeServersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configured MCP Servers (\(servers.count))")
                .font(.headline)

            if servers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("No MCP Servers Configured")
                        .font(.subheadline.weight(.medium))
                    Text("Click on a popular connector above or add a custom stdio command to expand Aura's tools.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)
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
        HStack(spacing: 12) {
            Image(systemName: "terminal")
                .font(.subheadline)
                .foregroundColor(server.isEnabled ? .blue : .secondary)
                .frame(width: 28, height: 28)
                .background((server.isEnabled ? Color.blue : Color.secondary).opacity(0.12))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(server.name)
                        .font(.subheadline.weight(.semibold))
                    Text(server.command)
                        .font(.system(size: 10, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(3)
                }

                if !server.args.isEmpty {
                    Text(server.args.joined(separator: " "))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
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
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(server.isEnabled ? Color.blue.opacity(0.15) : Color.primary.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Sheets
    private var addCustomServerSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Add Custom MCP Server")
                    .font(.headline)
                Spacer()
                Button("Cancel") { isShowingAddServerSheet = false }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server Name")
                        .font(.caption.weight(.semibold))
                    TextField("e.g. my-local-db", text: $customName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Executable Command")
                        .font(.caption.weight(.semibold))
                    TextField("e.g. npx, python3, uvx, node", text: $customCommand)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Arguments (space separated)")
                        .font(.caption.weight(.semibold))
                    TextField("e.g. -y @modelcontextprotocol/server-sqlite --db-path /tmp/app.db", text: $customArgs)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Environment Variables (KEY=VALUE, comma separated)")
                        .font(.caption.weight(.semibold))
                    TextField("e.g. API_KEY=abc123xyz, DEBUG=1", text: $customEnv)
                        .textFieldStyle(.roundedBorder)
                }
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
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480, height: 380)
    }

    private func presetConfigurationSheet(for preset: QuickConnectorPreset) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(preset.title, systemImage: preset.iconName)
                    .font(.headline)
                    .foregroundColor(preset.color)
                Spacer()
                Button("Cancel") { selectedPreset = nil }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            Text(preset.instructions)
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(preset.inputLabel)
                    .font(.caption.weight(.semibold))
                TextField(preset.inputPlaceholder, text: $presetInputValue)
                    .textFieldStyle(.roundedBorder)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Install Connector") {
                    installPresetWithInput(preset, input: presetInputValue)
                    selectedPreset = nil
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(presetInputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
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
        case .notion:
            server = MCPServerConfig(
                name: "notion",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-notion"],
                env: ["NOTION_API_KEY": cleanInput],
                isEnabled: true
            )
        case .gmail:
            server = MCPServerConfig(
                name: "gmail",
                command: "uvx",
                args: ["gmail-mcp", "--credentials", cleanInput],
                env: [:],
                isEnabled: true
            )
        case .sqlite:
            server = MCPServerConfig(
                name: "sqlite",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", cleanInput],
                env: [:],
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
    case gmail = "Gmail"
    case notion = "Notion"
    case github = "GitHub"
    case fetch = "Web Fetch"
    case sqlite = "SQLite"

    var id: String { rawValue }
    var title: String { rawValue }

    var serverName: String {
        switch self {
        case .gmail: return "gmail"
        case .notion: return "notion"
        case .github: return "github"
        case .fetch: return "fetch"
        case .sqlite: return "sqlite"
        }
    }

    var subtitle: String {
        switch self {
        case .gmail: return "Read, search, and draft emails"
        case .notion: return "Query workspace databases & docs"
        case .github: return "Inspect repos, pull requests, issues"
        case .fetch: return "Fetch & convert web pages to markdown"
        case .sqlite: return "Query local SQLite database files"
        }
    }

    var iconName: String {
        switch self {
        case .gmail: return "envelope.fill"
        case .notion: return "doc.text.fill"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .fetch: return "globe"
        case .sqlite: return "cylinder.split.1x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .gmail: return .red
        case .notion: return .purple
        case .github: return .gray
        case .fetch: return .blue
        case .sqlite: return .orange
        }
    }

    var requiresInput: Bool {
        self != .fetch
    }

    var instructions: String {
        switch self {
        case .gmail: return "Provide the path to your Google Cloud credentials.json file. Run 'uvx gmail-mcp' once in terminal to authorize."
        case .notion: return "Enter your Notion Integration Token (secret_...) created in Notion Developers portal."
        case .github: return "Enter your GitHub Personal Access Token (classic or fine-grained with repo scope)."
        case .sqlite: return "Enter the absolute file path to your local SQLite database file."
        case .fetch: return "Installs @modelcontextprotocol/server-fetch instantly."
        }
    }

    var inputLabel: String {
        switch self {
        case .gmail: return "Path to credentials.json"
        case .notion: return "Notion API Token"
        case .github: return "GitHub Access Token"
        case .sqlite: return "Database File Path"
        case .fetch: return ""
        }
    }

    var inputPlaceholder: String {
        switch self {
        case .gmail: return "/Users/you/credentials.json"
        case .notion: return "secret_abc123..."
        case .github: return "ghp_..."
        case .sqlite: return "/Users/you/Documents/app.db"
        case .fetch: return ""
        }
    }

    var defaultCommand: String {
        switch self {
        case .gmail: return "uvx"
        default: return "npx"
        }
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
