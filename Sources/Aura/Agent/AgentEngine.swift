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
        onInterimText: (@Sendable (String) -> Void)? = nil,
        onToolStart: (@Sendable (ToolCallRecord) -> Void)? = nil,
        onToolFinish: (@Sendable (ToolCallRecord) -> Void)? = nil
    ) async throws -> (interimSpeech: String?, finalAnswer: String, executedTools: [ToolCallRecord]) {
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
        let (compOn, termOn, scriptOn, webOn, fsOn, visionOn, thinkingEffort) = await MainActor.run {
            let cfg = CapabilityConfigManager.shared
            return (cfg.isComputerEnabled, cfg.isTerminalEnabled, cfg.isMacScriptEnabled, cfg.isWebEnabled, cfg.isFileSystemEnabled, cfg.isVisionEnabled, cfg.resolvedEffortLevel)
        }

        // Only disallow tools that are specifically replaced (Bash -> terminal, AskUser -> GUI) or explicitly turned OFF by user
        var disallowed: [String] = ["Bash", "AskUser", "ToolSearch", "PauseForHuman"]
        if !compOn { disallowed.append("computer") }
        if !termOn { disallowed.append("terminal") }
        if !scriptOn { disallowed.append("mac_script") }
        if !webOn { disallowed.append(contentsOf: ["WebFetch", "WebSearch"]) }
        if !fsOn { disallowed.append(contentsOf: ["Read", "Write", "Edit", "Glob", "Grep"]) }
        if !visionOn { disallowed.append(contentsOf: ["view_image", "take_screenshot"]) }

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

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let currentDateString = dateFormatter.string(from: Date())

        let structuredSystemPrompt = """
        <SYSTEM_ENVIRONMENT>
        * Platform: macOS (Darwin)
        * Shell: /bin/zsh
        * Date: \(currentDateString)
        * Active Native Tools: [\(toolListSummary)]
        * Active Domain Skills: [\(skillListSummary.isEmpty ? "none" : skillListSummary)]
        * Connected MCP Connectors: [\(mcpSummary)]
        </SYSTEM_ENVIRONMENT>

        <OPERATING_PROCEDURE>
        1. UNDERSTAND & ROUTE INTENT:
           - For informational or capability questions (e.g. "What can you do?", "What tools are active?"), answer directly and conversationally from your knowledge without running shell or diagnostic tools.
           - For action or inspection requests (checking screen, searching repositories, opening apps, taking screenshots, running terminal commands), immediately invoke the relevant tool.
        2. ATOMIC EXECUTION:
           - Call the narrowest, most targeted tool for the task.
        3. ACTION GROUNDING & ZERO UNFULFILLED PROMISES (CRITICAL):
           - When answering requires visual inspection or checking system/window state (e.g. "Which software is this open?"), you MUST invoke the appropriate tool (such as `take_screenshot`) in the EXACT SAME TURN.
           - NEVER end your turn on an unfulfilled conversational promise like "let me take a quick look at your screen" without attaching the tool call. If you speak, attach the tool in the same turn so it executes immediately.
        4. EVALUATE TOOL RESULTS:
           - Always inspect the latest tool result. If a tool returns SUCCESS or valid UI/terminal output, the action succeeded. Never claim an action failed if the tool succeeded.
        5. FAST-FAIL ON PERMISSIONS:
           - Only if a tool returns an explicit permission error regarding Accessibility, Assistive access, or Screen Recording, inform the user and direct them to Aura's Permissions Hub in Settings. Do not loop across multiple tools.
        </OPERATING_PROCEDURE>

        <TOOL_ROUTING_MATRIX>
        * VISUAL & SCREEN INSPECTION:
          - Use `take_screenshot` to view the user's screen, read visible windows, OCR text, or check which application is open. Full image pixels are attached directly to your context.
          - Use `view_image` to inspect image files located on disk.
        * SCRIPTABLE MAC APPS:
          - Use `mac_script` for scriptable apps (Notes, Music, Finder, Safari, Calendar, Reminders). Never tunnel osascript through terminal.
        * SHELL & DEVELOPER TASKS:
          - Use `terminal` for non-interactive zsh commands, git operations, file inspection, and local build tools.
        * UI ACCESSIBILITY AUTOMATION:
          - Use `computer` strictly for interactive UI clicking and typing. First call action 'observe', then use the exact element_id for 'click' or 'set_value'. Never invent element IDs.
        * DOMAIN SKILLS:
          - Use `Skill` to invoke active domain workflows when the user intent matches a skill.
        </TOOL_ROUTING_MATRIX>

        <SPEECH_AND_FORMATTING>
        * Keep responses direct, natural, and conversational.
        * Do NOT use markdown asterisks (*, **), raw code fences, or bullet lists in conversational summaries so responses sound clean and fluid when spoken aloud.
        </SPEECH_AND_FORMATTING>
        """

        let options = AgentOptions(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            provider: provider,
            systemPrompt: structuredSystemPrompt,
            maxTurns: 10,
            thinking: .adaptive,
            permissionMode: .bypassPermissions,
            tools: allTools,
            mcpServers: mcpConfigs,
            hookRegistry: hookRegistry,
            skillRegistry: activeSkillReg,
            disallowedTools: disallowed,
            effort: thinkingEffort
        )

        let agent = createAgent(options: options)
        onPhaseUpdate?("Thinking...")

        var result = await agent.prompt(historyContext)
        var executed = await toolTracker.records
        var interimSpeech: String? = nil

        // Runtime Continuation Guard:
        // If the model produced text promising an action/inspection (e.g. "let me take a look at your screen")
        // but emitted 0 tool calls in that turn, proactively trigger the tool so the user is never left hanging!
        let lowerText = result.text.lowercased()
        let promisesInspection = (
            lowerText.contains("let me take a") ||
            lowerText.contains("let me look") ||
            lowerText.contains("let me check") ||
            lowerText.contains("taking a look") ||
            lowerText.contains("checking your screen") ||
            lowerText.contains("take a quick look") ||
            lowerText.contains("let me see what")
        )

        if executed.isEmpty && promisesInspection {
            let capturedInterim = result.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            interimSpeech = capturedInterim
            onInterimText?(capturedInterim)
            onPhaseUpdate?("Inspecting screen...")

            let nudgePrompt = "You stated you would take a look or check the screen, but no tool was invoked in that turn. Please call the required tool (such as take_screenshot) now to complete the user's request."
            let continuationResult = await agent.prompt(nudgePrompt)
            let continuationExecuted = await toolTracker.records
            if !continuationExecuted.isEmpty {
                executed = continuationExecuted
                result = continuationResult
            }
        }

        var answer = result.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if answer.isEmpty {
            if let errors = result.errors, !errors.isEmpty {
                answer = "Error: " + errors.joined(separator: "\n")
            } else {
                answer = "Completed turn with no final text."
            }
        }

        return (interimSpeech, answer, executed)
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

        func detectImagePath(name: String, args: String, out: String) -> String? {
            // 1. If output contains "Saved to /path/to/img.jpg" or "Screenshot saved to /..."
            if let range = out.range(of: #"(?:Saved to |screenshot saved to )([^\s\n]+\.(?:png|jpg|jpeg|webp|bmp|heic))"#, options: [.regularExpression, .caseInsensitive]) {
                let match = String(out[range])
                if let colonRange = match.range(of: #"/.*"#, options: .regularExpression) {
                    let path = String(match[colonRange]).trimmingCharacters(in: CharacterSet(charactersIn: " .,"))
                    if FileManager.default.fileExists(atPath: path) {
                        return path
                    }
                }
            }
            // 2. If view_image tool, extract file_path from arguments
            if name.lowercased() == "view_image" {
                if let range = args.range(of: #""file_path"\s*:\s*"([^"]+)""#, options: .regularExpression) {
                    let full = String(args[range])
                    let components = full.components(separatedBy: "\"")
                    if components.count >= 4 {
                        let path = (components[3] as NSString).expandingTildeInPath
                        if FileManager.default.fileExists(atPath: path) {
                            return path
                        }
                    }
                }
            }
            // 3. Fallback: Check if output itself has an absolute image file path
            if let range = out.range(of: #"(/Users/[^\s\n]+\.(?:png|jpg|jpeg|webp|bmp|heic))"#, options: [.regularExpression, .caseInsensitive]) {
                let path = String(out[range]).trimmingCharacters(in: CharacterSet(charactersIn: " .,"))
                if FileManager.default.fileExists(atPath: path) {
                    return path
                }
            }
            return nil
        }

        if let idx = records.firstIndex(where: { $0.id == id || ($0.toolName == toolName && $0.status == .running) }) {
            records[idx].output = output
            records[idx].status = status
            records[idx].latencyMs = elapsed
            records[idx].imagePath = detectImagePath(name: toolName, args: records[idx].argumentsJson, out: output)
            return records[idx]
        } else {
            let img = detectImagePath(name: toolName, args: "", out: output)
            let rec = ToolCallRecord(
                id: id,
                toolName: toolName,
                argumentsJson: "",
                output: output,
                status: status,
                latencyMs: elapsed,
                imagePath: img
            )
            records.append(rec)
            return rec
        }
    }
}
