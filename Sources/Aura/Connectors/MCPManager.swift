import Foundation
import OpenAgentSDK

/// Configuration for an external Model Context Protocol server.
public struct MCPServerConfig: Identifiable, Codable, Sendable {
    public var id: String { name }
    public let name: String
    public let command: String
    public let args: [String]
    public let env: [String: String]
    public var isEnabled: Bool

    public init(
        name: String,
        command: String,
        args: [String] = [],
        env: [String: String] = [:],
        isEnabled: Bool = true
    ) {
        self.name = name
        self.command = command
        self.args = args
        self.env = env
        self.isEnabled = isEnabled
    }
}

/// Manages Model Context Protocol client instances and community tool connections.
public actor MCPManager {
    public static let shared = MCPManager()

    private var registeredServers: [String: MCPServerConfig] = [:]

    public init() {
        if let data = UserDefaults.standard.data(forKey: "aura_mcp_servers"),
           let decoded = try? JSONDecoder().decode([String: MCPServerConfig].self, from: data) {
            self.registeredServers = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(registeredServers) {
            UserDefaults.standard.set(data, forKey: "aura_mcp_servers")
        }
    }

    /// Adds or updates an MCP server configuration.
    public func register(server: MCPServerConfig) {
        registeredServers[server.name] = server
        persist()
    }

    /// Toggles an MCP server's enabled status.
    public func toggleServer(name: String) {
        guard var server = registeredServers[name] else { return }
        server.isEnabled.toggle()
        registeredServers[name] = server
        persist()
    }

    /// Removes an MCP server configuration.
    public func remove(serverName: String) {
        registeredServers.removeValue(forKey: serverName)
        persist()
    }

    /// Lists all currently registered MCP servers.
    public func listServers() -> [MCPServerConfig] {
        Array(registeredServers.values).sorted { $0.name < $1.name }
    }

    /// Converts stored configs into OpenAgentSDK native McpServerConfig formats for AgentOptions.
    public func toMcpServerConfigs() -> [String: McpServerConfig] {
        var result: [String: McpServerConfig] = [:]
        for (name, cfg) in registeredServers where cfg.isEnabled {
            result[name] = .stdio(McpStdioConfig(
                command: cfg.command,
                args: cfg.args,
                env: cfg.env
            ))
        }
        return result
    }

    /// Discovers tools provided by a given MCP server.
    public func discoverTools(for serverName: String) async throws -> [ConnectorTool] {
        guard let _ = registeredServers[serverName] else {
            throw ConnectorError.unknownTool("Server \(serverName) not found")
        }
        // In Phase 5: connect via swift-sdk to stdio/SSE and perform tools/list
        return [
            ConnectorTool(
                id: "\(serverName)_query",
                name: "\(serverName) Query",
                description: "Execute MCP tool on \(serverName)"
            )
        ]
    }
}
