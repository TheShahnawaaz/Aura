import XCTest
import OpenAgentSDK
@testable import Aura

final class AgentSDKTests: XCTestCase {
    func testToolDefinitionsValidity() {
        let tools = ToolRegistry.shared.toolDefinitions
        XCTAssertEqual(tools.count, 3, "Aura should expose only its three generic native capabilities")

        let names = tools.compactMap { tool -> String? in
            let fn = tool["function"] as? [String: Any]
            return fn?["name"] as? String
        }

        XCTAssertEqual(Set(names), ["computer", "terminal", "mac_script"])
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
            name: "terminal",
            argumentsJson: "{\"command\": \"echo 'Aura Agent SDK'\"}"
        )

        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("Aura Agent SDK"))
        XCTAssertGreaterThanOrEqual(result.latencyMs, 0)
    }

    func testOpenAgentSDKNativeTools() {
        let tools = AuraTools.allTools()
        XCTAssertEqual(tools.count, 3, "AuraTools should register three generic native tools")

        let toolNames = tools.map { $0.name }
        XCTAssertEqual(Set(toolNames), ["computer", "terminal", "mac_script"])
    }

    func testControlPolicyRequiresApprovalForMutation() {
        let terminal = GuardrailsEngine.shared.evaluateTool(name: "terminal", input: ["command": "rm -rf /tmp/example"])
        let script = GuardrailsEngine.shared.evaluateTool(name: "mac_script", input: ["source": "tell application \"Finder\" to delete every file"])
        XCTAssertFalse(terminal.isSafe)
        XCTAssertFalse(script.isSafe)

        let safeTerminal = GuardrailsEngine.shared.evaluateTool(name: "terminal", input: ["command": "echo 'Hello World'"])
        let safeScript = GuardrailsEngine.shared.evaluateTool(name: "mac_script", input: ["source": "tell application \"Notes\" to activate"])
        XCTAssertTrue(safeTerminal.isSafe)
        XCTAssertTrue(safeScript.isSafe)
    }

    func testAppleScriptAndStaleElementGuards() async throws {
        let output = try await AppleScriptService.shared.execute(language: "applescript", source: "return \"Aura\"")
        XCTAssertEqual(output, "Aura")
        XCTAssertThrowsError(try ComputerControlService.shared.click(elementId: "expired:1"))
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

}
