import Foundation

/// Compatibility registry for UI and tests. AgentEngine uses AuraTools directly; this
/// registry mirrors the same three capabilities instead of maintaining a second tool set.
public final class ToolRegistry: @unchecked Sendable {
    public static let shared = ToolRegistry()
    private init() {}

    public var toolDefinitions: [[String: Any]] {
        [
            definition(name: "take_screenshot", properties: [
                "app_bundle_id": ["type": "string", "description": "Optional bundle identifier to focus on a specific app"]
            ], required: []),
            definition(name: "computer", properties: [
                "action": ["type": "string", "enum": ["observe", "click", "set_value", "press_key", "scroll", "screenshot"]]
            ], required: ["action"]),
            definition(name: "terminal", properties: ["command": ["type": "string"], "cwd": ["type": "string"]], required: ["command"]),
            definition(name: "mac_script", properties: ["language": ["type": "string", "enum": ["applescript", "javascript"]], "source": ["type": "string"]], required: ["language", "source"])
        ]
    }

    public func executeTool(name: String, argumentsJson: String) async -> (output: String, success: Bool, latencyMs: Int) {
        let started = CFAbsoluteTimeGetCurrent()
        let arguments = parse(argumentsJson)
        do {
            let output: String
            switch name {
            case "take_screenshot":
                output = try ComputerControlService.shared.takeScreenshot()
            case "terminal":
                let command = try required(arguments["command"] as? String, "command")
                let safety = GuardrailsEngine.shared.evaluateTool(name: name, input: arguments)
                if case .requiresConfirmation(let request) = safety {
                    let approved = await ApprovalCoordinator.shared.requestApproval(request: request)
                    guard approved else { throw AuraToolError.actionDenied("User cancelled action: \(request.title)") }
                }
                let cwd = (arguments["cwd"] as? String).map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
                let result = try await TerminalService.shared.execute(command: command, currentDirectory: cwd)
                output = result.stdout.isEmpty ? result.stderr : result.stdout
            case "mac_script":
                let language = try required(arguments["language"] as? String, "language")
                let source = try required(arguments["source"] as? String, "source")
                let safety = GuardrailsEngine.shared.evaluateTool(name: name, input: arguments)
                if case .requiresConfirmation(let request) = safety {
                    let approved = await ApprovalCoordinator.shared.requestApproval(request: request)
                    guard approved else { throw AuraToolError.actionDenied("User cancelled action: \(request.title)") }
                }
                output = try await AppleScriptService.shared.execute(language: language, source: source)
            case "computer":
                output = try await executeComputer(arguments)
            default:
                throw AuraToolError.invalidAction(name)
            }
            return (output.trimmingCharacters(in: .whitespacesAndNewlines), true, elapsed(since: started))
        } catch {
            return (error.localizedDescription, false, elapsed(since: started))
        }
    }

    private func executeComputer(_ arguments: [String: Any]) async throws -> String {
        let action = try required(arguments["action"] as? String, "action")
        switch action {
        case "observe":
            let json = try ComputerControlService.shared.observe(appBundleId: arguments["app_bundle_id"] as? String)
            return "SUCCESS: Accessibility permission is active and working. UI observed successfully:\n\(json)"
        case "click": return try ComputerControlService.shared.click(elementId: try required(arguments["element_id"] as? String, "element_id"))
        case "set_value": return try ComputerControlService.shared.setValue(elementId: try required(arguments["element_id"] as? String, "element_id"), value: try required(arguments["value"] as? String, "value"))
        case "press_key": return try ComputerControlService.shared.pressKeys(arguments["keys"] as? [String] ?? [])
        case "scroll": return try ComputerControlService.shared.scroll(direction: arguments["direction"] as? String ?? "down", amount: arguments["amount"] as? Int ?? 3)
        case "screenshot": return try ComputerControlService.shared.takeScreenshot()
        default: throw AuraToolError.invalidAction(action)
        }
    }

    private func definition(name: String, properties: [String: Any], required: [String]) -> [String: Any] {
        ["type": "function", "function": ["name": name, "parameters": ["type": "object", "properties": properties, "required": required]]]
    }

    private func parse(_ json: String) -> [String: Any] {
        guard let data = json.data(using: .utf8), let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return result
    }

    private func required(_ value: String?, _ name: String) throws -> String {
        guard let value, !value.isEmpty else { throw AuraToolError.missingArgument(name) }
        return value
    }

    private func elapsed(since started: CFAbsoluteTime) -> Int { Int((CFAbsoluteTimeGetCurrent() - started) * 1000) }
}
