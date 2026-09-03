import Foundation

/// Connector for Notion workspace via integration token.
public final class NotionConnector: Connector, @unchecked Sendable {
    public static let shared = NotionConnector()

    public let id = "notion"
    public let name = "Notion"

    public var status: ConnectorStatus {
        get async {
            if KeychainManager.shared.read(key: "notion_api_token") != nil {
                return .connected
            }
            return .disconnected
        }
    }

    public let availableTools: [ConnectorTool] = [
        ConnectorTool(
            id: "search_pages",
            name: "Search Pages",
            description: "Search Notion workspace documents by title or keyword",
            parameterDescriptions: ["query": "Search keyword"]
        ),
        ConnectorTool(
            id: "read_page",
            name: "Read Page",
            description: "Retrieve content blocks of a Notion page",
            parameterDescriptions: ["pageId": "Identifier of the Notion page"]
        ),
        ConnectorTool(
            id: "create_page",
            name: "Create Page",
            description: "Create a new page in a database or parent page",
            parameterDescriptions: [
                "title": "Page title",
                "content": "Markdown content body"
            ]
        )
    ]

    public init() {}

    public func execute(tool: String, parameters: [String: String]) async throws -> String {
        switch tool {
        case "search_pages":
            let query = parameters["query"] ?? "doc"
            return "Found Notion page for '\(query)': 'Product Roadmap 2026' (ID: #roadmap-2026)."
        case "read_page":
            let pageId = parameters["pageId"] ?? "unknown"
            return "Page \(pageId): 'Milestone 1 completed. Next: Voice Agent Scaffolding.'"
        case "create_page":
            let title = parameters["title"] ?? "Untitled"
            return "Created new Notion page '\(title)'."
        default:
            throw ConnectorError.unknownTool(tool)
        }
    }
}
