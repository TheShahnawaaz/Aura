import XCTest
import OpenAgentSDK
@testable import Aura

final class AgentSDKTests: XCTestCase {
    func testToolDefinitionsValidity() {
        let tools = ToolRegistry.shared.toolDefinitions
        XCTAssertEqual(tools.count, 4, "Aura should expose its native capabilities including take_screenshot")

        let names = tools.compactMap { tool -> String? in
            let fn = tool["function"] as? [String: Any]
            return fn?["name"] as? String
        }

        XCTAssertEqual(Set(names), ["take_screenshot", "computer", "terminal", "mac_script"])
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
        XCTAssertEqual(tools.count, 5, "AuraTools should register five native tools (computer, take_screenshot, terminal, mac_script, view_image)")

        let toolNames = tools.map { $0.name }
        XCTAssertEqual(Set(toolNames), ["computer", "take_screenshot", "terminal", "mac_script", "view_image"])
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
        XCTAssertGreaterThanOrEqual(registry.allSkills.count, 3)
    }

    func testCapabilityConfigManagerAndFiltering() async {
        let config = await CapabilityConfigManager.shared
        await MainActor.run {
            config.setSkillEnabled("productivity", isEnabled: false)
        }
        let activeSkills = await AuraSkillRegistry.shared.activeSkillsRegistry()
        let activeNames = activeSkills.allSkills.map { $0.name }
        XCTAssertFalse(activeNames.contains("productivity"), "Disabled skill should be excluded from activeSkillsRegistry")

        await MainActor.run {
            config.setSkillEnabled("productivity", isEnabled: true)
        }
        let restoredSkills = await AuraSkillRegistry.shared.activeSkillsRegistry()
        let restoredNames = restoredSkills.allSkills.map { $0.name }
        XCTAssertTrue(restoredNames.contains("productivity"), "Re-enabled skill should be present in activeSkillsRegistry")

        // Test sub-action gating
        let allowed = await config.isSubActionAllowed(tool: "computer", action: "observe")
        XCTAssertTrue(allowed.allowed)

        await MainActor.run {
            config.allowObserve = false
        }
        let denied = await config.isSubActionAllowed(tool: "computer", action: "observe")
        XCTAssertFalse(denied.allowed)

        await MainActor.run {
            config.allowObserve = true
        }
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

    func testModelDiscoveryService_strictZeroFallbackOnEmptyKey() async {
        do {
            _ = try await ModelDiscoveryService.shared.fetchModels(provider: "gemini", apiKey: "")
            XCTFail("Expected missingApiKey error when key is empty")
        } catch let error as ModelDiscoveryError {
            switch error {
            case .missingApiKey(let provider):
                XCTAssertEqual(provider, "Google Gemini")
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testCustomProviderRegisteredAndAccessible() {
        let registry = ProviderRegistry.shared
        let custom = registry.find(idOrName: "custom")
        XCTAssertEqual(custom.providerId, "custom")
        XCTAssertEqual(custom.displayName, "Custom / OpenAI-Compatible")
        XCTAssertEqual(registry.userDefaultsKeyForApiKey(providerId: "custom"), "customApiKey")
    }

    func testLocalProxyModelDiscoveryIfAvailable() async {
        // Test discovery against the running local proxy if reachable
        do {
            let models = try await ModelDiscoveryService.shared.fetchModels(
                provider: "custom",
                apiKey: "123456",
                customBaseURL: "http://127.0.0.1:8317/v1",
                forceRefresh: true
            )
            XCTAssertFalse(models.isEmpty)
            XCTAssertTrue(models.contains(where: { $0.modelId == "gemini-3-flash" || $0.modelId.contains("flash") }))
        } catch {
            // If proxy is not running during CI, error is acceptable
        }
    }

    @MainActor
    func testCapabilityConfigManagerVision() {
        let mgr = CapabilityConfigManager.shared
        mgr.isVisionEnabled = true
        XCTAssertTrue(mgr.isToolEnabled("view_image"))
        XCTAssertTrue(mgr.isToolEnabled("vision"))

        mgr.isVisionEnabled = false
        XCTAssertFalse(mgr.isToolEnabled("view_image"))
        XCTAssertFalse(mgr.isToolEnabled("vision"))

        // Reset
        mgr.isVisionEnabled = true
    }

    func testViewImageToolExecution() async throws {
        // Create a temporary 120x80 test PNG image
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: 120,
            height: 80,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            XCTFail("Failed to create CGContext")
            return
        }
        ctx.setFillColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        ctx.fill(CGRect(x: 0, y: 0, width: 120, height: 80))
        guard let image = ctx.makeImage() else {
            XCTFail("Failed to make CGImage")
            return
        }

        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("aura-test-image-\(UUID().uuidString).png")
        guard let dest = CGImageDestinationCreateWithURL(tempUrl as CFURL, "public.png" as CFString, 1, nil) else {
            XCTFail("Failed to create destination")
            return
        }
        CGImageDestinationAddImage(dest, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(dest))

        defer {
            try? FileManager.default.removeItem(at: tempUrl)
        }

        // Execute view_image tool
        let tool = AuraTools.viewImageTool
        let context = ToolContext(
            cwd: FileManager.default.currentDirectoryPath,
            toolUseId: "test-tool-call",
            agentId: "test-agent",
            sessionId: "test-session"
        )
        let result = await tool.call(input: ["file_path": tempUrl.path], context: context)
        XCTAssertFalse(result.isError)
        XCTAssertNotNil(result.typedContent)

        // Check typed content contains .image
        let hasImage = result.typedContent?.contains(where: { item in
            if case .image(let data, let mime) = item {
                return !data.isEmpty && mime == "image/jpeg"
            }
            return false
        }) ?? false
        XCTAssertTrue(hasImage, "view_image should return typed image content block")
    }
}
