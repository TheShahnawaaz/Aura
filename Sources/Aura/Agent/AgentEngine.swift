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

        await hookRegistry.register(.postToolUseFailure, definition: HookDefinition(
            handler: { input in
                let toolName = input.toolName ?? "Tool"
                let errStr = input.error ?? "Tool execution failed"

                var argsJson = ""
                if let inputObj = input.toolInput,
                   let data = try? JSONSerialization.data(withJSONObject: inputObj),
                   let str = String(data: data, encoding: .utf8) {
                    argsJson = str
                }

                await toolTracker.addRecord(ToolCallRecord(
                    toolName: toolName,
                    argumentsJson: argsJson,
                    output: errStr,
                    status: .failure,
                    latencyMs: 150
                ))
                return nil
            }
        ))

        let mcpConfigs = await MCPManager.shared.toMcpServerConfigs()

        var allTools = await AuraTools.enabledTools()
        let activeSkillReg = await AuraSkillRegistry.shared.activeSkillsRegistry()
        if !activeSkillReg.allSkills.isEmpty {
            allTools.append(createSkillTool(registry: activeSkillReg))
        }

        let toolListSummary = allTools.map { $0.name }.joined(separator: ", ")
        let skillListSummary = activeSkillReg.allSkills.map { $0.name }.joined(separator: ", ")

        let options = AgentOptions(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            provider: provider,
            systemPrompt: """
            You are Aura, an intelligent macOS voice and desktop AI assistant.
            Active native capabilities: [\(toolListSummary)].
            Active domain skills: [\(skillListSummary.isEmpty ? "none" : skillListSummary)].

            CORE RULES:
            1. CONVERSATIONAL & CAPABILITY QUESTIONS: When the user asks about your capabilities, tools, or registered skills (e.g. "What skills do you have?"), answer directly and conversationally from your knowledge without invoking tools. Explicitly state your active tools and skills: [\(toolListSummary)] and skills: [\(skillListSummary)]. Do NOT use terminal or filesystem commands to search external app directories (such as Claude) for skills.
            2. ACTION & INSPECTION REQUESTS: Only invoke tools when the user explicitly requests an action (such as opening an application, creating a note, clicking UI, running a script) or asks to inspect system files.
            3. EVALUATING TOOL RESULTS & GROUNDING: Always inspect the latest tool result. If a tool succeeds or returns UI observation data / SUCCESS, the action SUCCEEDED and permissions ARE active. Confirm the success clearly to the user. Never claim an action failed if the tool succeeded. Do not be confused by prior conversation turns or by previous error messages visible inside observed window text.
            4. FAST-FAIL ON REAL ERRORS: Only if a tool actually returns an explicit error message regarding Accessibility, Assistive access, or Screen Recording, inform the user and point them to Aura's Permissions Hub in Settings. Do not retry 4-5 alternative tools in a loop.
            5. APP AUTOMATION: Prefer mac_script for scriptable apps (Notes, Music, Finder, Safari, Calendar). Never tunnel AppleScript through terminal. Apps without scripting dictionaries (like Clock) or web logins (like YouTube subscription) should not be forced with multiple blind AppleScript attempts; open the app or guide the user instead.
            6. UI CONTROL: For app UI tasks, first call computer with action observe. Use element IDs only from that response, re-observe after every state-changing action, and never guess an element ID.
            7. SKILLS: Use the Skill tool to inspect or execute active registered domain skills when the user's intent matches a skill.
            8. MULTI-STEP REASONING: Call tools iteratively when required, but stop immediately if an action encounters a hard permission barrier.
            9. CONTEXT RETENTION: Always remember facts the user shared throughout the entire conversation.
            10. CONCISE, NATURAL SPEECH: Keep responses direct, friendly, and conversational. Do NOT use markdown asterisks (*, **), bullet lists, or headers so the response sounds clean when spoken aloud.
            """,
            maxTurns: 10,
            permissionMode: .bypassPermissions,
            tools: allTools,
            mcpServers: mcpConfigs,
            hookRegistry: hookRegistry,
            skillRegistry: activeSkillReg
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
                let status = t.status == .success ? "SUCCESS" : "FAILED"
                context += "  ↳ [Tool \(t.toolName) (\(status))]: \(t.output.prefix(150))\n"
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
