import Foundation
import OpenAgentSDK
import CoreGraphics
import ImageIO

/// The agent has generic capabilities. Concrete actions are expressed as typed input,
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

public struct TakeScreenshotInput: Codable, Sendable {
    public let app_bundle_id: String?
}

public struct TerminalInput: Codable, Sendable {
    public let command: String
    public let cwd: String?
}

public struct MacScriptInput: Codable, Sendable {
    public let language: String
    public let source: String
}

public struct ViewImageInput: Codable, Sendable {
    public let filePath: String

    public init(filePath: String) {
        self.filePath = filePath
    }

    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
    }
}

public enum AuraTools {
    public static func allTools() -> [ToolProtocol] { [computerTool, takeScreenshotTool, terminalTool, macScriptTool, viewImageTool] }

    @MainActor
    public static func enabledTools() -> [ToolProtocol] {
        var tools: [ToolProtocol] = []
        let config = CapabilityConfigManager.shared
        if config.isComputerEnabled { tools.append(computerTool) }
        if config.isVisionEnabled && config.allowScreenshots { tools.append(takeScreenshotTool) }
        if config.isTerminalEnabled { tools.append(terminalTool) }
        if config.isMacScriptEnabled { tools.append(macScriptTool) }
        if config.isVisionEnabled { tools.append(viewImageTool) }
        return tools
    }

    public static let takeScreenshotTool: ToolProtocol = defineTool(
        name: "take_screenshot",
        description: """
        Captures the visible screen (or optionally a specific app window) as an image.
        Full visual pixels are attached directly into your context for OCR, reading text, window inspection, identifying open software, or verifying UI state changes.
        - USE FOR: Identifying currently open software/windows, reading on-screen text, checking UI layouts, visual inspection, or verifying UI changes.
        - DO NOT USE FOR: Manipulating buttons or typing text (use `computer` or `mac_script` instead).
        - PARAMETERS: `app_bundle_id` is optional. Omit it to capture the entire main desktop screen.
        """,
        inputSchema: [
            "type": "object",
            "properties": [
                "app_bundle_id": [
                    "type": "string",
                    "description": "Optional application bundle identifier (e.g. com.apple.Safari) to focus on a specific app"
                ]
            ]
        ],
        isReadOnly: true
    ) { (input: TakeScreenshotInput, _: ToolContext) async throws -> ToolExecuteResult in
        let check = await CapabilityConfigManager.shared.isSubActionAllowed(tool: "take_screenshot", action: "screenshot")
        if !check.allowed {
            throw AuraToolError.actionDisabled(check.reason ?? "Screenshot capture is disabled in Capabilities Settings.")
        }
        let cap = try ComputerControlService.shared.captureScreenshotData()
        return ToolExecuteResult(
            typedContent: [
                .text("Screenshot captured successfully (\(cap.width)x\(cap.height)). Saved to \(cap.path)."),
                .image(data: cap.data, mimeType: cap.mimeType)
            ],
            isError: false
        )
    }

    public static let computerTool: ToolProtocol = defineTool(
        name: "computer",
        description: """
        Interacts with macOS UI elements via Accessibility.
        - WORKFLOW: First call action 'observe' to inspect the UI hierarchy and obtain valid element IDs. Then use only element_id values returned from that exact observation. Re-observe after every state-changing action.
        - PRECONDITIONS: Element IDs expire after every UI action. Never guess element IDs.
        - DO NOT USE FOR: Taking screenshots to view the screen (use `take_screenshot` instead), or automating scriptable apps like Music/Notes/Finder (use `mac_script` instead).
        """,
        inputSchema: [
            "type": "object",
            "properties": [
                "action": ["type": "string", "enum": ["observe", "click", "set_value", "press_key", "scroll"]],
                "app_bundle_id": ["type": "string", "description": "Required for observe unless the frontmost app is intended, for example com.apple.TextEdit"],
                "element_id": ["type": "string", "description": "An opaque ID returned by the newest observe response (required for click and set_value)"],
                "value": ["type": "string", "description": "Text for set_value"],
                "keys": ["type": "array", "items": ["type": "string"], "description": "One key plus optional cmd, control, option, or shift modifiers"],
                "direction": ["type": "string", "enum": ["up", "down", "left", "right"]],
                "amount": ["type": "integer"]
            ],
            "required": ["action"]
        ],
        isReadOnly: false
    ) { (input: ComputerInput, _: ToolContext) async throws -> ToolExecuteResult in
        let check = await CapabilityConfigManager.shared.isSubActionAllowed(tool: "computer", action: input.action)
        if !check.allowed {
            throw AuraToolError.actionDisabled(check.reason ?? "Action is disabled in Capabilities Settings.")
        }

        switch input.action.lowercased() {
        case "observe":
            let json = try ComputerControlService.shared.observe(appBundleId: input.app_bundle_id)
            return ToolExecuteResult(content: "SUCCESS: Accessibility permission is active and working. UI observed successfully:\n\(json)", isError: false)
        case "click":
            let res = try ComputerControlService.shared.click(elementId: try required(input.element_id, named: "element_id"))
            return ToolExecuteResult(content: res, isError: false)
        case "set_value":
            let res = try ComputerControlService.shared.setValue(
                elementId: try required(input.element_id, named: "element_id"),
                value: try required(input.value, named: "value")
            )
            return ToolExecuteResult(content: res, isError: false)
        case "press_key":
            let res = try ComputerControlService.shared.pressKeys(input.keys ?? [])
            return ToolExecuteResult(content: res, isError: false)
        case "scroll":
            let res = try ComputerControlService.shared.scroll(direction: input.direction ?? "down", amount: input.amount ?? 3)
            return ToolExecuteResult(content: res, isError: false)
        case "screenshot":
            let cap = try ComputerControlService.shared.captureScreenshotData()
            return ToolExecuteResult(
                typedContent: [
                    .text("Screenshot captured successfully (\(cap.width)x\(cap.height)). Saved to \(cap.path)."),
                    .image(data: cap.data, mimeType: cap.mimeType)
                ],
                isError: false
            )
        default:
            throw AuraToolError.invalidAction(input.action)
        }
    }

    public static let viewImageTool: ToolProtocol = defineTool(
        name: "view_image",
        description: "Inspects and views an image file on disk (PNG, JPEG, WebP, GIF, BMP, HEIC). Returns the visual image pixels directly into your context so you can read text, analyze diagrams, inspect mockups, or describe photos.",
        inputSchema: [
            "type": "object",
            "properties": [
                "file_path": [
                    "type": "string",
                    "description": "Path to the image file to inspect (e.g. ~/Desktop/screenshot.png)"
                ]
            ],
            "required": ["file_path"]
        ],
        isReadOnly: true
    ) { (input: ViewImageInput, _: ToolContext) async throws -> ToolExecuteResult in
        let check = await CapabilityConfigManager.shared.isVisionEnabled
        if !check {
            throw AuraToolError.actionDisabled("Vision and image inspection is currently disabled in Capabilities Settings.")
        }

        let resolvedPath = (input.filePath as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: resolvedPath)
        guard FileManager.default.fileExists(atPath: resolvedPath) else {
            throw AuraToolError.missingArgument("Image file not found at path: \(resolvedPath)")
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw AuraToolError.invalidAction("Unable to decode image from \(resolvedPath)")
        }

        let originalWidth = image.width
        let originalHeight = image.height
        let maxDim = 1568
        let targetW: Int
        let targetH: Int
        if originalWidth > maxDim || originalHeight > maxDim {
            if originalWidth > originalHeight {
                targetW = maxDim
                targetH = max(1, Int(Double(originalHeight) * Double(maxDim) / Double(originalWidth)))
            } else {
                targetH = maxDim
                targetW = max(1, Int(Double(originalWidth) * Double(maxDim) / Double(originalHeight)))
            }
        } else {
            targetW = originalWidth
            targetH = originalHeight
        }

        let processed: CGImage
        if targetW != originalWidth || targetH != originalHeight {
            let cs = CGColorSpaceCreateDeviceRGB()
            guard let ctx = CGContext(
                data: nil,
                width: targetW,
                height: targetH,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: cs,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw AuraToolError.invalidAction("Failed to create graphics context for resizing.")
            }
            ctx.interpolationQuality = .high
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: targetW, height: targetH))
            guard let scaled = ctx.makeImage() else {
                throw AuraToolError.invalidAction("Failed to downscale image.")
            }
            processed = scaled
        } else {
            processed = image
        }

        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(mutableData as CFMutableData, "public.jpeg" as CFString, 1, nil) else {
            throw AuraToolError.invalidAction("Failed to create image destination.")
        }
        let opts: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.82]
        CGImageDestinationAddImage(dest, processed, opts as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw AuraToolError.invalidAction("Failed to finalize image compression.")
        }
        let data = mutableData as Data

        return ToolExecuteResult(
            typedContent: [
                .text("Loaded image: \(resolvedPath) (\(originalWidth)x\(originalHeight))."),
                .image(data: data, mimeType: "image/jpeg")
            ],
            isError: false
        )
    }

    public static let terminalTool: ToolProtocol = defineTool(
        name: "terminal",
        description: """
        Executes a non-interactive zsh shell command on macOS for development, git, filesystem, and system inspection.
        - USE FOR: Git operations (git status, log, diff), filesystem commands (ls, cat, find), checking running processes (ps, pgrep), reading configurations, and compiling code.
        - DO NOT USE FOR:
          * Interactive commands requiring continuous TTY input (e.g., vim, nano, top, sudo).
          * GUI app interaction (use `mac_script` or `computer` instead).
          * Running `osascript` directly (use `mac_script` instead so Apple Events permissions are audited).
        - PARAMETERS: `command` is required. `cwd` is optional working directory.
        - RETURNS: Command stdout or stderr output.
        """,
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
        description: """
        Executes AppleScript or JavaScript for Automation (JXA) directly via the macOS automation engine.
        - USE FOR: Controlling scriptable macOS applications such as Notes, Music, Finder, Safari, Mail, Reminders, and Calendar.
        - DO NOT USE FOR: Shell commands (use `terminal` instead) or non-scriptable apps without an AppleScript dictionary (use `computer` instead).
        - EXAMPLES:
          * Play music: tell application "Music" to play
          * Make note: tell application "Notes" to make new note with properties {name:"Title", body:"Content"}
          * Open URL: tell application "Safari" to open location "https://apple.com"
        - PARAMETERS: `language` must be 'applescript' or 'javascript', and `source` is the script code.
        """,
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
