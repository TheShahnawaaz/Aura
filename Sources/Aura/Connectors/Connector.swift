import Foundation

/// Describes a callable tool provided by a connector.
public struct ConnectorTool: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let parameterDescriptions: [String: String]

    public init(
        id: String,
        name: String,
        description: String,
        parameterDescriptions: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.parameterDescriptions = parameterDescriptions
    }
}

/// Status of an integration connector.
public enum ConnectorStatus: Equatable, Sendable {
    case disconnected
    case connected
    case error(String)
}

/// Base protocol for all built-in and external service connectors.
public protocol Connector: Sendable {
    var id: String { get }
    var name: String { get }
    var status: ConnectorStatus { get async }
    var availableTools: [ConnectorTool] { get }

    func execute(tool: String, parameters: [String: String]) async throws -> String
}
