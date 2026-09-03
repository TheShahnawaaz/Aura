import Foundation
import OpenAgentSDK

/// The agent has three generic capabilities. Concrete actions are expressed as typed input,
/// which keeps the model surface compact without turning the policy layer into prompt text.
public struct ComputerInput: Codable, Sendable {
    public let action: String
    public let app_bundle_id: String?
    public let element_id: String?
    public let value: String?
    public let keys: [String]?
    public let direction: String?
    public let amount: Int?
}

public struct TerminalInput: Codable, Sendable {
    public let command: String
    public let cwd: String?
}

public struct MacScriptInput: Codable, Sendable {
    public let language: String
    public let source: String
}

public enum AuraTools {
    public static func allTools() -> [ToolProtocol] { [computerTool, terminalTool, macScriptTool] }

    @MainActor
    public static func enabledTools() -> [ToolProtocol] {
        var tools: [ToolProtocol] = []
        let config = CapabilityConfigManager.shared
        if config.isComputerEnabled { tools.append(computerTool) }
        if config.isTerminalEnabled { tools.append(terminalTool) }
        if config.isMacScriptEnabled { tools.append(macScriptTool) }
        return tools
    }

    public static let computerTool: ToolProtocol = defineTool(
        name: "computer",
        description: "Controls the visible macOS UI. First call observe, then use only element_id values from that exact observation. Re-observe after every UI-changing action. Never invent element IDs.",
        inputSchema: [
            "type": "object",
            "properties": [
                "action": ["type": "string", "enum": ["observe", "click", "set_value", "press_key", "scroll", "screenshot"]],
                "app_bundle_id": ["type": "string", "description": "Required for observe unless the frontmost app is intended, for example com.apple.TextEdit"],
                "element_id": ["type": "string", "description": "An opaque ID returned by the newest observe response"],
                "value": ["type": "string", "description": "Text for set_value"],
                "keys": ["type": "array", "items": ["type": "string"], "description": "One key plus optional cmd, control, option, or shift modifiers"],
                "direction": ["type": "string", "enum": ["up", "down", "left", "right"]],
                "amount": ["type": "integer"]
            ],
            "required": ["action"]
        ],
        isReadOnly: false
    ) { (input: ComputerInput, _: ToolContext) async throws -> String in
        let check = await CapabilityConfigManager.shared.isSubActionAllowed(tool: "computer", action: input.action)
        if !check.allowed {
            throw AuraToolError.actionDisabled(check.reason ?? "Action is disabled in Capabilities Settings.")
        }

        switch input.action.lowercased() {
        case "observe":
            let json = try ComputerControlService.shared.observe(appBundleId: input.app_bundle_id)
            return "SUCCESS: Accessibility permission is active and working. UI observed successfully:\n\(json)"
        case "click": return try ComputerControlService.shared.click(elementId: try required(input.element_id, named: "element_id"))
        case "set_value": return try ComputerControlService.shared.setValue(
            elementId: try required(input.element_id, named: "element_id"),
            value: try required(input.value, named: "value")
        )
        case "press_key": return try ComputerControlService.shared.pressKeys(input.keys ?? [])
        case "scroll": return try ComputerControlService.shared.scroll(direction: input.direction ?? "down", amount: input.amount ?? 3)
        case "screenshot": return try ComputerControlService.shared.takeScreenshot()
        default: throw AuraToolError.invalidAction(input.action)
        }
    }

    public static let terminalTool: ToolProtocol = defineTool(
        name: "terminal",
        description: "Runs a zsh command for local development and system work. Prefer direct read-only commands. Do not use terminal to run osascript; use mac_script so Aura can audit Apple Events.",
        inputSchema: [
            "type": "object",
            "properties": [
                "command": ["type": "string"],
                "cwd": ["type": "string", "description": "Optional existing working directory"]
            ],
            "required": ["command"]
        ],
        isReadOnly: false
    ) { (input: TerminalInput, _: ToolContext) async throws -> String in
        let check = await CapabilityConfigManager.shared.isSubActionAllowed(tool: "terminal", action: "execute")
        if !check.allowed {
            throw AuraToolError.actionDisabled(check.reason ?? "Terminal execution is disabled in Capabilities Settings.")
        }

        let safety = GuardrailsEngine.shared.evaluateTool(name: "terminal", input: ["command": input.command])
        if case .requiresConfirmation(let request) = safety {
            let approved = await ApprovalCoordinator.shared.requestApproval(request: request)
            guard approved else { throw AuraToolError.actionDenied("User cancelled action: \(request.title)") }
        }
        let cwd = input.cwd.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
        let result = try await TerminalService.shared.execute(command: input.command, currentDirectory: cwd)
        let output = result.stdout.isEmpty ? result.stderr : result.stdout
        return output.isEmpty ? "Command completed with no output." : output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static let macScriptTool: ToolProtocol = defineTool(
        name: "mac_script",
        description: "Runs AppleScript or JavaScript for Automation (JXA) using the macOS automation system. Prefer it for apps with a scripting dictionary. Provide language as applescript or javascript.",
        inputSchema: [
            "type": "object",
            "properties": [
                "language": ["type": "string", "enum": ["applescript", "javascript"]],
                "source": ["type": "string"]
            ],
            "required": ["language", "source"]
        ]
    ) { (input: MacScriptInput, _: ToolContext) async throws -> String in
        let check = await CapabilityConfigManager.shared.isSubActionAllowed(tool: "mac_script", action: input.language)
        if !check.allowed {
            throw AuraToolError.actionDisabled(check.reason ?? "Language \(input.language) is disabled in Capabilities Settings.")
        }

        let safety = GuardrailsEngine.shared.evaluateTool(name: "mac_script", input: ["source": input.source])
        if case .requiresConfirmation(let request) = safety {
            let approved = await ApprovalCoordinator.shared.requestApproval(request: request)
            guard approved else { throw AuraToolError.actionDenied("User cancelled action: \(request.title)") }
        }
        return try await AppleScriptService.shared.execute(language: input.language, source: input.source)
    }

    private static func required(_ value: String?, named name: String) throws -> String {
        guard let value, !value.isEmpty else { throw AuraToolError.missingArgument(name) }
        return value
    }
}

public enum AuraToolError: LocalizedError {
    case invalidAction(String)
    case missingArgument(String)
    case actionDenied(String)
    case actionDisabled(String)
    case confirmationRequired(ActionConfirmationRequest)

    public var errorDescription: String? {
        switch self {
        case .invalidAction(let action): return "Unsupported computer action: \(action)."
        case .missingArgument(let name): return "Missing required argument: \(name)."
        case .actionDenied(let reason): return reason
        case .actionDisabled(let reason): return "Disabled: \(reason)"
        case .confirmationRequired(let request): return "Confirmation required: \(request.title). \(request.description)"
        }
    }
}
