import Foundation

/// Represents an individual message in a multi-turn chat session.
public struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let role: Role
    public var content: String
    public let timestamp: Date
    public var toolCalls: [ToolCallRecord]
    public let isVoice: Bool
    public var imagePaths: [String]?

    public enum Role: String, Codable, Sendable {
        case user
        case assistant
        case tool
        case system
    }

    public init(
        id: String = UUID().uuidString,
        role: Role,
        content: String,
        timestamp: Date = Date(),
        toolCalls: [ToolCallRecord] = [],
        isVoice: Bool = false,
        imagePaths: [String]? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.toolCalls = toolCalls
        self.isVoice = isVoice
        self.imagePaths = imagePaths
    }
}

/// Represents a single tool call performed by the agent during a turn.
public struct ToolCallRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let toolName: String
    public let argumentsJson: String
    public var output: String
    public var status: Status
    public var latencyMs: Int
    public var isExpanded: Bool
    public var imagePath: String?

    public enum Status: String, Codable, Sendable {
        case running
        case success
        case failure
    }

    public init(
        id: String = UUID().uuidString,
        toolName: String,
        argumentsJson: String,
        output: String = "",
        status: Status = .running,
        latencyMs: Int = 0,
        isExpanded: Bool = false,
        imagePath: String? = nil
    ) {
        self.id = id
        self.toolName = toolName
        self.argumentsJson = argumentsJson
        self.output = output
        self.status = status
        self.latencyMs = latencyMs
        self.isExpanded = isExpanded
        self.imagePath = imagePath
    }
}

/// A persistent multi-turn conversation thread.
public struct ConversationSession: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var title: String
    public let createdAt: Date
    public var updatedAt: Date
    public var messages: [ChatMessage]

    public init(
        id: String = UUID().uuidString,
        title: String = "New Conversation",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [ChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }
}

/// Raw tool call parsed from the OpenAI/Gemini API response.
public struct RawToolCall: Sendable {
    public let id: String
    public let name: String
    public let arguments: String

    public init(id: String, name: String, arguments: String) {
        self.id = id
        self.name = name
        self.arguments = arguments
    }
}
