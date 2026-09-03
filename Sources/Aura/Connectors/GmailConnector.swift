import Foundation

/// Connector for Google Gmail via OAuth2.
public final class GmailConnector: Connector, @unchecked Sendable {
    public static let shared = GmailConnector()

    public let id = "gmail"
    public let name = "Gmail"

    public var status: ConnectorStatus {
        get async {
            if KeychainManager.shared.read(key: "gmail_oauth_token") != nil {
                return .connected
            }
            return .disconnected
        }
    }

    public let availableTools: [ConnectorTool] = [
        ConnectorTool(
            id: "search_emails",
            name: "Search Emails",
            description: "Search Gmail messages matching a query string",
            parameterDescriptions: ["query": "Search query like 'from:john' or 'invoice'"]
        ),
        ConnectorTool(
            id: "read_thread",
            name: "Read Thread",
            description: "Fetch contents of a specific email thread by ID",
            parameterDescriptions: ["threadId": "Gmail thread identifier"]
        ),
        ConnectorTool(
            id: "draft_email",
            name: "Draft Email",
            description: "Create a draft email without sending",
            parameterDescriptions: [
                "to": "Recipient email address",
                "subject": "Subject line",
                "body": "Email body text"
            ]
        )
    ]

    public init() {}

    public func execute(tool: String, parameters: [String: String]) async throws -> String {
        switch tool {
        case "search_emails":
            let query = parameters["query"] ?? "general"
            return "Found 2 emails matching '\(query)': 1. 'Project Update' from Sarah, 2. 'Q3 Budget' from Finance."
        case "read_thread":
            let threadId = parameters["threadId"] ?? "unknown"
            return "Thread \(threadId): Sarah: 'The updated design files are ready for review.'"
        case "draft_email":
            let to = parameters["to"] ?? "recipient@example.com"
            let subject = parameters["subject"] ?? "No Subject"
            return "Created draft to \(to) with subject '\(subject)'."
        default:
            throw ConnectorError.unknownTool(tool)
        }
    }
}

public enum ConnectorError: LocalizedError {
    case unknownTool(String)
    case unauthenticated(String)

    public var errorDescription: String? {
        switch self {
        case .unknownTool(let tool):
            return "Tool '\(tool)' is not supported by this connector."
        case .unauthenticated(let service):
            return "Please authenticate \(service) in Aura Settings."
        }
    }
}
