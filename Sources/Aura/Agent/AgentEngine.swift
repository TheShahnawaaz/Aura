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
        onPhaseUpdate: (@Sendable (String) -> Void)? = nil,
        onToolStart: (@Sendable (ToolCallRecord) -> Void)? = nil,
        onToolFinish: (@Sendable (ToolCallRecord) -> Void)? = nil
    ) async throws -> (finalAnswer: String, executedTools: [ToolCallRecord]) {
        let apiKey = LLMService.shared.resolveApiKey()
        let baseURL = LLMService.shared.resolveBaseURL()
        let model = LLMService.shared.resolveModel()
        let provider: LLMProvider = baseURL.contains("anthropic") ? .anthropic : .openai

        // Build conversation history context prefix so the agent has full context of prior turns
        let historyContext = buildHistoryContext(session: session, currentPrompt: userPrompt)

        // Setup HookRegistry for safety guardrails and real-time progressive tool tracking
        let hookRegistry = HookRegistry()
        let toolTracker = ToolExecutionTracker()

        await hookRegistry.register(.preToolUse, definition: HookDefinition(
            handler: { input in
                let toolName = input.toolName ?? "Tool"
                let callId = input.toolUseId ?? UUID().uuidString
                onPhaseUpdate?("Running \(toolName)...")

                var argsJson = ""
                if let inputObj = input.toolInput,
                   let data = try? JSONSerialization.data(withJSONObject: inputObj, options: [.prettyPrinted, .withoutEscapingSlashes]),
                   let str = String(data: data, encoding: .utf8) {
                    argsJson = str
                } else if let inputObj = input.toolInput {
                    argsJson = "\(inputObj)"
                }

                let record = await toolTracker.start(id: callId, toolName: toolName, argsJson: argsJson)
                onToolStart?(record)
                return nil
            }
        ))

        await hookRegistry.register(.postToolUse, definition: HookDefinition(
            handler: { input in
                let toolName = input.toolName ?? "Tool"
                let callId = input.toolUseId ?? UUID().uuidString
                var outputStr = ""
                if let out = input.toolOutput {
                    outputStr = "\(out)"
                }

                let record = await toolTracker.finish(id: callId, toolName: toolName, output: outputStr, status: .success)
                onToolFinish?(record)
                return nil
            }
        ))

        await hookRegistry.register(.postToolUseFailure, definition: HookDefinition(
            handler: { input in
                let toolName = input.toolName ?? "Tool"
                let callId = input.toolUseId ?? UUID().uuidString
                let errStr = input.error ?? "Tool execution failed"

                let record = await toolTracker.finish(id: callId, toolName: toolName, output: errStr, status: .failure)
                onToolFinish?(record)
                return nil
            }
        ))

        let mcpConfigs = await MCPManager.shared.toMcpServerConfigs()

        var allTools = await AuraTools.enabledTools()
        let activeSkillReg = await AuraSkillRegistry.shared.activeSkillsRegistry()
        if !activeSkillReg.allSkills.isEmpty {
            allTools.append(createSkillTool(registry: activeSkillReg))
        }

        // Read configuration from CapabilityConfigManager
        let (compOn, termOn, scriptOn, webOn, fsOn) = await MainActor.run {
            let cfg = CapabilityConfigManager.shared
            return (cfg.isComputerEnabled, cfg.isTerminalEnabled, cfg.isMacScriptEnabled, cfg.isWebEnabled, cfg.isFileSystemEnabled)
        }

        // Only disallow tools that are specifically replaced (Bash -> terminal, AskUser -> GUI) or explicitly turned OFF by user
        var disallowed: [String] = ["Bash", "AskUser", "ToolSearch", "PauseForHuman"]
        if !compOn { disallowed.append("computer") }
        if !termOn { disallowed.append("terminal") }
        if !scriptOn { disallowed.append("mac_script") }
        if !webOn { disallowed.append(contentsOf: ["WebFetch", "WebSearch"]) }
        if !fsOn { disallowed.append(contentsOf: ["Read", "Write", "Edit", "Glob", "Grep"]) }

        var activeToolNames = allTools.map { $0.name }
        if webOn {
            activeToolNames.append(contentsOf: ["WebFetch", "WebSearch"])
        }
        if fsOn {
            activeToolNames.append(contentsOf: ["Read", "Write", "Edit", "Glob", "Grep"])
        }
        let mcpServerNames = mcpConfigs.keys.sorted()
        let mcpSummary = mcpServerNames.isEmpty ? "none" : mcpServerNames.joined(separator: ", ")
        let toolListSummary = activeToolNames.joined(separator: ", ")
        let skillListSummary = activeSkillReg.allSkills.map { $0.name }.joined(separator: ", ")

        let options = AgentOptions(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            provider: provider,
            systemPrompt: """
            You are Aura, an intelligent macOS voice and desktop AI assistant.
            Active native tools: [\(toolListSummary)].
            Active domain skills: [\(skillListSummary.isEmpty ? "none" : skillListSummary)].
            Connected MCP connectors: [\(mcpSummary)].

            CORE RULES:
            1. CONVERSATIONAL & CAPABILITY QUESTIONS: When the user asks about your capabilities, tools, connected MCP servers, or registered skills, answer directly and conversationally from your knowledge without running shell commands. You have native macOS automation (computer, terminal, mac_script), built-in web tools (WebFetch for fetching URLs and reading web pages, WebSearch for web search queries), built-in filesystem tools (Read, Write, Edit, Glob, Grep), connected MCP connectors ([\(mcpSummary)]), and domain skills ([\(skillListSummary)]). If the user asks about a connected tool (such as WebFetch or a connected MCP server like GitHub), explain that it is active and available.
            2. ACTION & INSPECTION REQUESTS: Only invoke tools when the user explicitly requests an action (such as fetching a webpage, searching repositories, opening an application, creating a note, clicking UI, running a script) or asks to inspect system files.
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
            skillRegistry: activeSkillReg,
            disallowedTools: disallowed
        )

        let agent = createAgent(options: options)
        onPhaseUpdate?("Thinking...")

        let result = await agent.prompt(historyContext)
        let executed = await toolTracker.records

        var answer = result.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if answer.isEmpty {
            if let errors = result.errors, !errors.isEmpty {
                answer = "Error: " + errors.joined(separator: "\n")
            } else {
                answer = "Completed turn with no final text."
            }
        }

        return (answer, executed)
    }

    private func buildHistoryContext(session: ConversationSession, currentPrompt: String) -> String {
        let history = session.messages.suffix(6)
        guard !history.isEmpty else { return currentPrompt }

        var lines: [String] = []
        lines.append("CONVERSATION CONTEXT SO FAR:")
        for msg in history {
            let roleLabel = msg.role == .user ? "User" : "Assistant"
            lines.append("\(roleLabel): \(msg.content)")
            if !msg.toolCalls.isEmpty {
                let toolSummaries = msg.toolCalls.map {
                    let statusTag = $0.status == .success ? "(SUCCESS)" : "(FAILED)"
                    let trimmedOutput = $0.output.prefix(120).replacingOccurrences(of: "\n", with: " ")
                    return "\($0.toolName) \(statusTag): \(trimmedOutput)"
                }.joined(separator: " | ")
                lines.append("  [Tool calls: \(toolSummaries)]")
            }
        }
        lines.append("\nCURRENT USER REQUEST:\n\(currentPrompt)")
        return lines.joined(separator: "\n")
    }
}

actor ToolExecutionTracker {
    var records: [ToolCallRecord] = []
    private var startTimes: [String: CFAbsoluteTime] = [:]

    func start(id: String, toolName: String, argsJson: String) -> ToolCallRecord {
        startTimes[id] = CFAbsoluteTimeGetCurrent()
        let record = ToolCallRecord(
            id: id,
            toolName: toolName,
            argumentsJson: argsJson,
            output: "",
            status: .running,
            latencyMs: 0
        )
        records.append(record)
        return record
    }

    func finish(id: String, toolName: String, output: String, status: ToolCallRecord.Status) -> ToolCallRecord {
        let started = startTimes[id] ?? CFAbsoluteTimeGetCurrent()
        let elapsed = max(Int((CFAbsoluteTimeGetCurrent() - started) * 1000), 1)

        if let idx = records.firstIndex(where: { $0.id == id || ($0.toolName == toolName && $0.status == .running) }) {
            records[idx].output = output
            records[idx].status = status
            records[idx].latencyMs = elapsed
            return records[idx]
        } else {
            let rec = ToolCallRecord(
                id: id,
                toolName: toolName,
                argumentsJson: "",
                output: output,
                status: status,
                latencyMs: elapsed
            )
            records.append(rec)
            return rec
        }
    }
}
