import Foundation
import SwiftUI

/// Central coordinator for multi-turn chat sessions, disk persistence, and ReAct agent execution.
@MainActor
public final class AgentSessionManager: ObservableObject {
    public static let shared = AgentSessionManager()

    @Published public var activeSession: ConversationSession
    @Published public var sessions: [ConversationSession] = []
    @Published public var selectedSessionId: String? = nil
    @Published public var isProcessing: Bool = false
    private init() {
        let loaded = SessionStorage.shared.loadAllSessions()
        if let first = loaded.first {
            self.sessions = loaded
            self.activeSession = first
            self.selectedSessionId = first.id
        } else {
            let initial = ConversationSession(title: "New Conversation")
            self.sessions = [initial]
            self.activeSession = initial
            self.selectedSessionId = nil
            SessionStorage.shared.saveSession(initial)
        }
    }

    /// Selects New Chat mode (nothing selected).
    public func selectNewChat() {
        selectedSessionId = nil
    }

    /// Creates a brand new conversation thread and sets it as active.
    @discardableResult
    public func createNewSession() -> ConversationSession {
        let newSession = ConversationSession(title: "New Conversation")
        sessions.insert(newSession, at: 0)
        activeSession = newSession
        selectedSessionId = newSession.id
        SessionStorage.shared.saveSession(newSession)
        return newSession
    }

    /// Selects an existing thread by ID, or nil for New Chat.
    public func selectSession(id: String?) {
        selectedSessionId = id
        if let id, let found = sessions.first(where: { $0.id == id }) {
            activeSession = found
        }
    }

    /// Renames a conversation thread.
    public func renameSession(id: String, newTitle: String) {
        let clean = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        if let idx = sessions.firstIndex(where: { $0.id == id }) {
            sessions[idx].title = clean
            sessions[idx].updatedAt = Date()
            if activeSession.id == id {
                activeSession.title = clean
                activeSession.updatedAt = Date()
            }
            SessionStorage.shared.saveSession(sessions[idx])
        }
    }

    /// Deletes a conversation thread from disk and memory.
    public func deleteSession(id: String) {
        SessionStorage.shared.deleteSession(id: id)
        sessions.removeAll(where: { $0.id == id })

        if selectedSessionId == id {
            selectedSessionId = nil
        }

        if activeSession.id == id {
            if let next = sessions.first {
                activeSession = next
            } else {
                let fresh = ConversationSession(title: "New Conversation")
                sessions = [fresh]
                activeSession = fresh
                selectedSessionId = nil
                SessionStorage.shared.saveSession(fresh)
            }
        }
    }

    /// Submits a user prompt.
    /// If an existing chat is selected, appends to it. If nothing is selected, starts a fresh new chat.
    @discardableResult
    public func processPrompt(text: String, isVoice: Bool) async -> String {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return "" }

        isProcessing = true

        // 1. Resolve destination session: selected chat or fresh new chat
        var targetSession: ConversationSession
        if let id = selectedSessionId, let existing = sessions.first(where: { $0.id == id }) {
            targetSession = existing
        } else {
            let fresh = ConversationSession(title: "New Conversation")
            sessions.insert(fresh, at: 0)
            targetSession = fresh
            activeSession = fresh
            selectedSessionId = fresh.id
            SessionStorage.shared.saveSession(fresh)
        }

        // 2. Append user message
        let userMsg = ChatMessage(role: .user, content: cleanText, isVoice: isVoice)
        targetSession.messages.append(userMsg)

        // 3. Immediately append initial assistant placeholder message for real-time progressive streaming
        let assistantMessageId = UUID().uuidString
        let initialAssistantMsg = ChatMessage(
            id: assistantMessageId,
            role: .assistant,
            content: "",
            toolCalls: [],
            isVoice: isVoice
        )
        targetSession.messages.append(initialAssistantMsg)
        targetSession.updatedAt = Date()
        activeSession = targetSession
        updateSessionInList(targetSession)

        // 4. Run ReAct Agent loop with real-time progressive callbacks
        var finalAnswer = "Understood."
        var executedTools: [ToolCallRecord] = []

        do {
            let result = try await AgentEngine.shared.runTurn(
                session: targetSession,
                userPrompt: cleanText,
                isVoice: isVoice,
                onPhaseUpdate: { phase in
                    Task { @MainActor in
                        AppState.shared.state = .processing(phase: phase)
                    }
                },
                onToolStart: { record in
                    Task { @MainActor in
                        guard let sIdx = self.sessions.firstIndex(where: { $0.id == targetSession.id }),
                              let mIdx = self.sessions[sIdx].messages.firstIndex(where: { $0.id == assistantMessageId }) else { return }
                        self.sessions[sIdx].messages[mIdx].toolCalls.append(record)
                        if self.activeSession.id == targetSession.id {
                            self.activeSession = self.sessions[sIdx]
                        }
                    }
                },
                onToolFinish: { record in
                    Task { @MainActor in
                        guard let sIdx = self.sessions.firstIndex(where: { $0.id == targetSession.id }),
                              let mIdx = self.sessions[sIdx].messages.firstIndex(where: { $0.id == assistantMessageId }) else { return }
                        if let tIdx = self.sessions[sIdx].messages[mIdx].toolCalls.firstIndex(where: { $0.id == record.id || ($0.toolName == record.toolName && $0.status == .running) }) {
                            self.sessions[sIdx].messages[mIdx].toolCalls[tIdx] = record
                        } else {
                            self.sessions[sIdx].messages[mIdx].toolCalls.append(record)
                        }
                        if self.activeSession.id == targetSession.id {
                            self.activeSession = self.sessions[sIdx]
                        }
                    }
                }
            )
            finalAnswer = result.finalAnswer
            executedTools = result.executedTools
        } catch {
            finalAnswer = "I ran into an issue: \(error.localizedDescription)"
        }

        // 5. Finalize assistant response message & persist
        if let sIdx = self.sessions.firstIndex(where: { $0.id == targetSession.id }),
           let mIdx = self.sessions[sIdx].messages.firstIndex(where: { $0.id == assistantMessageId }) {
            self.sessions[sIdx].messages[mIdx].content = finalAnswer
            if !executedTools.isEmpty {
                self.sessions[sIdx].messages[mIdx].toolCalls = executedTools
            }
            self.sessions[sIdx].updatedAt = Date()
            self.activeSession = self.sessions[sIdx]
            SessionStorage.shared.saveSession(self.sessions[sIdx])
            targetSession = self.sessions[sIdx]
        }

        // 6. Auto-titling if this is a newly created thread
        if targetSession.title == "New Conversation" && targetSession.messages.count <= 2 {
            let sessionToTitle = targetSession.id
            Task.detached(priority: .utility) {
                let aiTitle = await LLMService.shared.generateTitle(for: cleanText)
                await MainActor.run {
                    self.renameSession(id: sessionToTitle, newTitle: aiTitle)
                }
            }
        }

        isProcessing = false

        // 7. Enforce User's Speech Rule:
        // - If spoken via microphone -> speak final answer aloud via TTS
        // - If typed via keyboard -> keep response silent
        if isVoice {
            SpeechSynthesizer.shared.speak(text: finalAnswer)
        } else {
            AppState.shared.state = .speaking(text: finalAnswer)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if case .speaking = AppState.shared.state {
                    AppState.shared.resetToIdle()
                }
            }
        }

        return finalAnswer
    }

    private func updateSessionInList(_ session: ConversationSession) {
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        }
    }
}
