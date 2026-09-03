import SwiftUI
import Combine

/// Lifecycle and interaction states of the Aura assistant.
public enum AssistantState: Equatable, Sendable {
    case idle
    case listening
    case processing(phase: String)
    case speaking(text: String)
    case awaitingConfirmation(ActionConfirmationRequest)
    case error(message: String)

    public var isListening: Bool {
        if case .listening = self { return true }
        return false
    }

    public var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }
}

/// Request for user approval before executing high-risk operations.
public struct ActionConfirmationRequest: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String
    public let commandOrAction: String
    public let riskLevel: RiskLevel

    public enum RiskLevel: String, Sendable {
        case low
        case medium
        case high
        case critical
    }

    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        commandOrAction: String,
        riskLevel: RiskLevel = .high
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.commandOrAction = commandOrAction
        self.riskLevel = riskLevel
    }
}

/// Information tracking a sub-agent executing a parallel task.
public struct ActiveSubAgent: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let iconName: String
    public var status: SubAgentStatus
    public var detail: String

    public enum SubAgentStatus: Equatable, Sendable {
        case pending
        case running
        case completed
        case failed(String)
    }

    public init(
        id: String,
        name: String,
        iconName: String = "gearshape.fill",
        status: SubAgentStatus = .pending,
        detail: String = ""
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.status = status
        self.detail = detail
    }
}

/// Global observable application state for Aura.
@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    // MARK: - Assistant State
    @Published public var state: AssistantState = .idle
    @Published public var transcript: String = ""
    @Published public var partialTranscript: String = ""
    @Published public var responseText: String = ""

    // MARK: - Audio & Visualization
    @Published public var audioLevel: Float = 0.0
    @Published public var isMuted: Bool = false

    // MARK: - Sub-Agents
    @Published public var activeAgents: [ActiveSubAgent] = []

    // MARK: - UI & HUD State
    @Published public var isHUDPresented: Bool = false
    @Published public var isSettingsOpen: Bool = false

    // MARK: - Preferences
    @Published public var autoSubmitOnSilence: Bool = false
    @Published public var hotkeyDisplayString: String = "⌥ Space"
    @Published public var activeSidebarTab: SidebarItem = .chat
    @Published public var isTurnCompletedPresented: Bool = false

    public init() {}

    // MARK: - State Transitions
    public func startListening() {
        isTurnCompletedPresented = false
        partialTranscript = ""
        transcript = ""
        responseText = ""
        activeAgents.removeAll()
        state = .listening
        isHUDPresented = true
    }

    public func stopListeningAndProcess() {
        state = .processing(phase: "Decomposing task...")
    }

    public func completeSpeakingAndPresent() {
        state = .idle
        isTurnCompletedPresented = true
    }

    public func dismissTurnCompleted() {
        isTurnCompletedPresented = false
        resetToIdle()
    }

    public func resetToIdle() {
        isTurnCompletedPresented = false
        state = .idle
        audioLevel = 0.0
        partialTranscript = ""
        activeAgents.removeAll()
    }

    public func updateSubAgent(id: String, status: ActiveSubAgent.SubAgentStatus, detail: String = "") {
        if let index = activeAgents.firstIndex(where: { $0.id == id }) {
            activeAgents[index].status = status
            if !detail.isEmpty {
                activeAgents[index].detail = detail
            }
        }
    }
}
