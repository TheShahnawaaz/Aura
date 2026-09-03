import XCTest
import OpenAgentSDK
@testable import Aura

final class AgentSDKTests: XCTestCase {
    func testToolDefinitionsValidity() {
        let tools = ToolRegistry.shared.toolDefinitions
        XCTAssertGreaterThanOrEqual(tools.count, 5, "Tool registry should expose native system tools")

        let names = tools.compactMap { tool -> String? in
            let fn = tool["function"] as? [String: Any]
            return fn?["name"] as? String
        }

        XCTAssertTrue(names.contains("open_application"))
        XCTAssertTrue(names.contains("adjust_volume"))
        XCTAssertTrue(names.contains("take_screenshot"))
        XCTAssertTrue(names.contains("list_files"))
        XCTAssertTrue(names.contains("execute_terminal_command"))
    }

    func testSessionSerializationAndStorage() {
        let testSession = ConversationSession(
            id: "test-session-\(UUID().uuidString)",
            title: "Test User Context",
            messages: [
                ChatMessage(role: .user, content: "My name is Alex", isVoice: true),
                ChatMessage(
                    role: .assistant,
                    content: "Nice to meet you, Alex!",
                    toolCalls: [
                        ToolCallRecord(
                            toolName: "open_application",
                            argumentsJson: "{\"app_name\":\"Notes\"}",
                            output: "Successfully opened Notes.",
                            status: .success,
                            latencyMs: 38
                        )
                    ],
                    isVoice: true
                ),
                ChatMessage(role: .user, content: "What is my name?", isVoice: false),
                ChatMessage(role: .assistant, content: "Your name is Alex.", isVoice: false)
            ]
        )

        // Save
        SessionStorage.shared.saveSession(testSession)

        // Load
        let all = SessionStorage.shared.loadAllSessions()
        let fetched = all.first(where: { $0.id == testSession.id })

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Test User Context")
        XCTAssertEqual(fetched?.messages.count, 4)
        XCTAssertEqual(fetched?.messages[1].toolCalls.first?.toolName, "open_application")
        XCTAssertEqual(fetched?.messages[1].toolCalls.first?.status, .success)
        XCTAssertEqual(fetched?.messages[3].content, "Your name is Alex.")

        // Clean up
        SessionStorage.shared.deleteSession(id: testSession.id)
        let afterDelete = SessionStorage.shared.loadAllSessions()
        XCTAssertFalse(afterDelete.contains(where: { $0.id == testSession.id }))
    }

    func testToolExecutionDispatcher() async {
        let result = await ToolRegistry.shared.executeTool(
            name: "execute_terminal_command",
            argumentsJson: "{\"command\": \"echo 'Aura Agent SDK'\"}"
        )

        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("Aura Agent SDK"))
        XCTAssertGreaterThanOrEqual(result.latencyMs, 0)
    }

    func testOpenAgentSDKNativeTools() {
        let tools = AuraTools.allTools()
        XCTAssertEqual(tools.count, 7, "AuraTools should register 7 strongly-typed native tools")

        let toolNames = tools.map { $0.name }
        XCTAssertTrue(toolNames.contains("open_application"))
        XCTAssertTrue(toolNames.contains("adjust_volume"))
        XCTAssertTrue(toolNames.contains("take_screenshot"))
        XCTAssertTrue(toolNames.contains("list_files"))
        XCTAssertTrue(toolNames.contains("execute_terminal_command"))
        XCTAssertTrue(toolNames.contains("search_emails"))
        XCTAssertTrue(toolNames.contains("query_notion"))
    }

    func testAuraSkillRegistryDomainSkills() {
        let registry = AuraSkillRegistry.shared.registry
        XCTAssertNotNil(registry)
    }

    func testMcpServerConfigBridging() async {
        let server = MCPServerConfig(
            name: "test-filesystem",
            command: "npx",
            args: ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
        )
        await MCPManager.shared.register(server: server)
        let configs = await MCPManager.shared.toMcpServerConfigs()

        XCTAssertNotNil(configs["test-filesystem"])
        await MCPManager.shared.remove(serverName: "test-filesystem")
    }

    func testAgentEngineLivePrompt() async throws {
        let session = ConversationSession(title: "Test Turn")
        let (answer, _) = try await AgentEngine.shared.runTurn(
            session: session,
            userPrompt: "Say hello in 3 words.",
            isVoice: false
        )
        print("AgentEngine live response: \(answer)")
        XCTAssertFalse(answer.isEmpty)
        XCTAssertNotEqual(answer, "Understood.")
    }

    func testProviderRegistryDefinitions() {
        let registry = ProviderRegistry.shared
        XCTAssertGreaterThanOrEqual(registry.providers.count, 7)

        let ids = registry.providers.map { $0.providerId }
        XCTAssertTrue(ids.contains("gemini"))
        XCTAssertTrue(ids.contains("openai"))
        XCTAssertTrue(ids.contains("anthropic"))
        XCTAssertTrue(ids.contains("groq"))
        XCTAssertTrue(ids.contains("deepseek"))
        XCTAssertTrue(ids.contains("mistral"))
        XCTAssertTrue(ids.contains("ollama"))
    }

    func testCapabilityFilterNonChatModels() {
        // Should reject non-chat / non-tool models
        XCTAssertFalse(ModelDiscoveryService.isChatAndReasoningModel(modelId: "gemini-2.5-flash-preview-tts"))
        XCTAssertFalse(ModelDiscoveryService.isChatAndReasoningModel(modelId: "tts-1-hd"))
        XCTAssertFalse(ModelDiscoveryService.isChatAndReasoningModel(modelId: "whisper-1"))
        XCTAssertFalse(ModelDiscoveryService.isChatAndReasoningModel(modelId: "text-embedding-3-small"))
        XCTAssertFalse(ModelDiscoveryService.isChatAndReasoningModel(modelId: "text-embedding-004"))
        XCTAssertFalse(ModelDiscoveryService.isChatAndReasoningModel(modelId: "dall-e-3"))

        // Should accept chat & reasoning models
        XCTAssertTrue(ModelDiscoveryService.isChatAndReasoningModel(modelId: "gemini-2.5-flash"))
        XCTAssertTrue(ModelDiscoveryService.isChatAndReasoningModel(modelId: "gpt-4o-mini"))
        XCTAssertTrue(ModelDiscoveryService.isChatAndReasoningModel(modelId: "llama-3.3-70b-versatile"))
        XCTAssertTrue(ModelDiscoveryService.isChatAndReasoningModel(modelId: "deepseek-chat"))
        XCTAssertTrue(ModelDiscoveryService.isChatAndReasoningModel(modelId: "claude-3-5-sonnet-20241022"))
    }

    func testModelDiscoveryFallbackPresets() {
        let fallbacks = ModelDiscoveryService.shared.fallbackModels(for: "gemini")
        XCTAssertFalse(fallbacks.isEmpty)
        XCTAssertTrue(fallbacks.contains(where: { $0.modelId == "gemini-2.5-flash" }))
    }

    func testToolCallingTurn() async throws {
        let session = ConversationSession(title: "Test Time")
        let (answer, executed) = try await AgentEngine.shared.runTurn(
            session: session,
            userPrompt: "What is the current time? Please check with the date command.",
            isVoice: false
        )
        print("AgentEngine answer: \(answer)")
        print("AgentEngine executed tools count: \(executed.count)")
        for t in executed {
            print("Tool: \(t.toolName), Output: \(t.output)")
        }
        XCTAssertFalse(answer.contains("Error: [400]"))
        XCTAssertGreaterThan(executed.count, 0)
    }
}
