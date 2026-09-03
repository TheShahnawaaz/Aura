import Foundation
import OpenAgentSDK

/// Configuration for an external Model Context Protocol server.
public struct MCPServerConfig: Identifiable, Codable, Sendable {
    public var id: String { name }
    public let name: String
    public let command: String
    public let args: [String]
    public let env: [String: String]

    public init(
        name: String,
        command: String,
        args: [String] = [],
        env: [String: String] = [:]
    ) {
        self.name = name
        self.command = command
        self.args = args
        self.env = env
    }
}

/// Manages Model Context Protocol client instances and community tool connections.
public actor MCPManager {
    public static let shared = MCPManager()

    private var registeredServers: [String: MCPServerConfig] = [:]

    public init() {}

    /// Adds or updates an MCP server configuration.
    public func register(server: MCPServerConfig) {
        registeredServers[server.name] = server
    }

    /// Removes an MCP server configuration.
    public func remove(serverName: String) {
        registeredServers.removeValue(forKey: serverName)
    }

    /// Lists all currently registered MCP servers.
    public func listServers() -> [MCPServerConfig] {
        Array(registeredServers.values)
    }

    /// Converts stored configs into OpenAgentSDK native McpServerConfig formats for AgentOptions.
    public func toMcpServerConfigs() -> [String: McpServerConfig] {
        var result: [String: McpServerConfig] = [:]
        for (name, cfg) in registeredServers {
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
