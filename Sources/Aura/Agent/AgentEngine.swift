import Foundation
import OpenAgentSDK

/// Coordinates multi-turn reasoning and tool execution using OpenAgentSDK.
public final class AgentEngine: @unchecked Sendable {
    public static let shared = AgentEngine()

    private init() {
        GeminiThoughtSignatureProtocol.register()
    }

    /// Runs a single turn using OpenAgentSDK in-process runtime, invoking tools and emitting live progress.
    public func runTurn(
        session: ConversationSession,
        userPrompt: String,
        isVoice: Bool,
        onPhaseUpdate: (@Sendable (String) -> Void)? = nil
    ) async throws -> (finalAnswer: String, executedTools: [ToolCallRecord]) {
        let apiKey = LLMService.shared.resolveApiKey()
        let baseURL = LLMService.shared.resolveBaseURL()
        let model = LLMService.shared.resolveModel()
        let provider: LLMProvider = baseURL.contains("anthropic") ? .anthropic : .openai

        // Build conversation history context prefix so the agent has full context of prior turns
        let historyContext = buildHistoryContext(session: session, currentPrompt: userPrompt)

        // Setup HookRegistry for safety guardrails and tool tracking
        let hookRegistry = HookRegistry()
        let toolTracker = ToolExecutionTracker()

        await hookRegistry.register(.preToolUse, definition: HookDefinition(
            handler: { input in
                let toolName = input.toolName ?? "Tool"
                onPhaseUpdate?("Running \(toolName)...")

                // Check security guardrails for commands
                if let dict = input.toolInput as? [String: Any],
                   let cmd = dict["command"] as? String {
                    let safety = GuardrailsEngine.shared.evaluateCommand(cmd)
                    if case .requiresConfirmation(let req) = safety {
                        return HookOutput(message: "Blocked dangerous command: \(req.commandOrAction)", block: true)
                    }
                }
                return nil
            }
        ))

        await hookRegistry.register(.postToolUse, definition: HookDefinition(
            handler: { input in
                let toolName = input.toolName ?? "Tool"
                var outputStr = ""
                if let out = input.toolOutput {
                    outputStr = "\(out)"
                }

                var argsJson = ""
                if let inputObj = input.toolInput,
                   let data = try? JSONSerialization.data(withJSONObject: inputObj),
                   let str = String(data: data, encoding: .utf8) {
                    argsJson = str
                }

                await toolTracker.addRecord(ToolCallRecord(
                    toolName: toolName,
                    argumentsJson: argsJson,
                    output: outputStr,
                    status: .success,
                    latencyMs: 150
                ))
                return nil
            }
        ))

        let mcpConfigs = await MCPManager.shared.toMcpServerConfigs()

        let options = AgentOptions(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            provider: provider,
            systemPrompt: """
            You are Aura, an intelligent macOS voice and desktop AI assistant.
            You have native tools to inspect and control macOS: launching applications, adjusting system volume, inspecting folders, taking screenshots, querying Notion, searching Gmail, and executing shell commands in zsh.

            CORE RULES:
            1. PROACTIVE TOOL EXECUTION: When the user asks about their system, files, installed tools, or programming languages (e.g. "what programming languages are installed", "what is on my desktop", "check my python version", "find my projects"), ALWAYS use your tools proactively (`execute_terminal_command` or `list_files`).
            2. NEVER REFUSE AS 'TOO BROAD': Never tell the user that an inspection request is "too broad" or refuse to check. Run safe shell commands to discover the answer and synthesize a crisp summary.
            3. MULTI-STEP REASONING: Call multiple tools iteratively until you have enough information to fulfill the user's intent.
            4. CONTEXT RETENTION: Always remember facts the user shared throughout the entire conversation.
            5. CONCISE, NATURAL SPEECH: Keep responses direct, friendly, and conversational. Do NOT use markdown asterisks (*, **), bullet lists, or headers so the response sounds clean when spoken aloud.
            """,
            maxTurns: 10,
            permissionMode: .bypassPermissions,
            tools: AuraTools.allTools(),
            mcpServers: mcpConfigs,
            hookRegistry: hookRegistry,
            skillRegistry: AuraSkillRegistry.shared.registry
        )

        let agent = createAgent(options: options)
        onPhaseUpdate?("Thinking...")

        let result = await agent.prompt(historyContext)
        let executed = await toolTracker.records

        var answer = result.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if answer.isEmpty {
            if let errors = result.errors, !errors.isEmpty {
                answer = "OpenAgentSDK Error: \(errors.joined(separator: ", "))"
            } else if let last = executed.last?.output, !last.isEmpty {
                answer = last
            } else {
                answer = "I processed your request, but received no message output."
            }
        }

        return (answer, executed)
    }

    private func buildHistoryContext(session: ConversationSession, currentPrompt: String) -> String {
        let history = session.messages.filter { $0.content != currentPrompt }.suffix(15)
        guard !history.isEmpty else {
            return currentPrompt
        }

        var context = "=== PRIOR CONVERSATION HISTORY ===\n"
        for msg in history {
            let role = msg.role == .user ? "User" : "Aura"
            context += "[\(role)]: \(msg.content)\n"
            for t in msg.toolCalls {
                context += "  ↳ [Tool \(t.toolName)]: \(t.output.prefix(150))\n"
            }
        }
        context += "=== END CONVERSATION HISTORY ===\n\n"
        context += "Current User Query: \(currentPrompt)"
        return context
    }
}

actor ToolExecutionTracker {
    var records: [ToolCallRecord] = []

    func addRecord(_ record: ToolCallRecord) {
        records.append(record)
    }
}
