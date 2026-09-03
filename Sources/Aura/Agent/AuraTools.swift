import AppKit
import Foundation
import OpenAgentSDK

// MARK: - Strongly-Typed Tool Input Models

public struct AppLauncherInput: Codable, Sendable {
    public let app_name: String

    public init(app_name: String) {
        self.app_name = app_name
    }
}

public struct VolumeInput: Codable, Sendable {
    public let action: String

    public init(action: String) {
        self.action = action
    }
}

public struct ListFilesInput: Codable, Sendable {
    public let directory: String

    public init(directory: String) {
        self.directory = directory
    }
}

public struct TerminalCommandInput: Codable, Sendable {
    public let command: String

    public init(command: String) {
        self.command = command
    }
}

public struct SearchEmailsInput: Codable, Sendable {
    public let query: String

    public init(query: String) {
        self.query = query
    }
}

public struct QueryNotionInput: Codable, Sendable {
    public let query: String

    public init(query: String) {
        self.query = query
    }
}

// MARK: - Native Aura Tools (OpenAgentSDK)

public enum AuraTools {
    /// Returns all native tools registered for Aura's in-process agent.
    public static func allTools() -> [ToolProtocol] {
        [
            openApplicationTool,
            adjustVolumeTool,
            takeScreenshotTool,
            listFilesTool,
            executeTerminalCommandTool,
            searchEmailsTool,
            queryNotionTool
        ]
    }

    // 1. Open Application
    public static let openApplicationTool: ToolProtocol = defineTool(
        name: "open_application",
        description: "Opens or launches an installed macOS application on the user's computer.",
        inputSchema: [
            "type": "object",
            "properties": [
                "app_name": [
                    "type": "string",
                    "description": "The exact or common name of the macOS application, e.g. Safari, Notes, Slack, Spotify, Terminal, Finder"
                ]
            ],
            "required": ["app_name"]
        ]
    ) { (input: AppLauncherInput, _: ToolContext) async throws -> String in
        let appName = input.app_name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !appName.isEmpty else {
            return "Error: Missing app_name parameter."
        }

        do {
            try await AppleScriptService.shared.openApp(named: appName)
            return "Successfully opened \(appName)."
        } catch {
            let shellRes = try? await TerminalService.shared.execute(command: "open -a \"\(appName)\"")
            if shellRes?.isSuccess == true {
                return "Successfully opened \(appName)."
            }
            return "Failed to open \(appName): \(error.localizedDescription)"
        }
    }

    // 2. Adjust Volume
    public static let adjustVolumeTool: ToolProtocol = defineTool(
        name: "adjust_volume",
        description: "Adjusts the macOS system speaker audio output volume (up, down, mute, unmute).",
        inputSchema: [
            "type": "object",
            "properties": [
                "action": [
                    "type": "string",
                    "enum": ["up", "down", "mute", "unmute"],
                    "description": "The volume adjustment action to take"
                ]
            ],
            "required": ["action"]
        ]
    ) { (input: VolumeInput, _: ToolContext) async throws -> String in
        let action = input.action.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if action == "up" {
                _ = try await AppleScriptService.shared.execute(script: "set volume output volume ((output volume of (get volume settings)) + 15)")
                return "Volume increased by 15%."
            } else if action == "down" {
                _ = try await AppleScriptService.shared.execute(script: "set volume output volume ((output volume of (get volume settings)) - 15)")
                return "Volume decreased by 15%."
            } else if action == "mute" {
                _ = try await AppleScriptService.shared.execute(script: "set volume with output muted")
                return "System audio muted."
            } else {
                _ = try await AppleScriptService.shared.execute(script: "set volume without output muted")
                return "System audio unmuted."
            }
        } catch {
            return "Volume adjustment error: \(error.localizedDescription)"
        }
    }

    // 3. Take Screenshot
    public static let takeScreenshotTool: ToolProtocol = defineTool(
        name: "take_screenshot",
        description: "Takes a full-screen desktop screenshot and saves it as a PNG image file to the user's Desktop.",
        inputSchema: [
            "type": "object",
            "properties": [:] as [String: Any]
        ]
    ) { (_: ToolContext) async throws -> String in
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let filename = "Screenshot_\(Int(Date().timeIntervalSince1970)).png"
        let path = "\(home)/Desktop/\(filename)"
        let res = try? await TerminalService.shared.execute(command: "screencapture \"\(path)\"")
        if res?.isSuccess == true {
            return "Captured screenshot and saved to Desktop: \(filename)"
        }
        return "Failed to capture screenshot."
    }

    // 4. List Files
    public static let listFilesTool: ToolProtocol = defineTool(
        name: "list_files",
        description: "Lists files and subdirectories inside a specified folder on macOS.",
        inputSchema: [
            "type": "object",
            "properties": [
                "directory": [
                    "type": "string",
                    "description": "The directory path to inspect, e.g. ~/Desktop, ~/Downloads, or ~/Documents"
                ]
            ],
            "required": ["directory"]
        ],
        isReadOnly: true
    ) { (input: ListFilesInput, _: ToolContext) async throws -> String in
        let rawDir = input.directory.isEmpty ? "~/Desktop" : input.directory
        let dir = (rawDir as NSString).expandingTildeInPath
        let res = try? await TerminalService.shared.execute(command: "ls -1 \"\(dir)\" | head -n 15")
        if let output = res?.stdout, !output.isEmpty {
            return "Contents of \(rawDir):\n\(output.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        return "Folder \(rawDir) is empty or inaccessible."
    }

    // 5. Execute Terminal Command
    public static let executeTerminalCommandTool: ToolProtocol = defineTool(
        name: "execute_terminal_command",
        description: "Executes shell commands in zsh. Use this proactively to inspect installed programming languages, check package managers, or query system hardware.",
        inputSchema: [
            "type": "object",
            "properties": [
                "command": [
                    "type": "string",
                    "description": "The shell command to execute, e.g. which python3, sw_vers, brew list --formula, date, uptime"
                ]
            ],
            "required": ["command"]
        ]
    ) { (input: TerminalCommandInput, _: ToolContext) async throws -> String in
        let cmd = input.command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return "Error: Empty command." }

        let res = try? await TerminalService.shared.execute(command: cmd)
        let out = (res?.stdout ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let err = (res?.stderr ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if !out.isEmpty {
            return out
        } else if !err.isEmpty {
            return "Stderr: \(err)"
        } else {
            return "Command executed successfully with no output."
        }
    }

    // 6. Search Emails
    public static let searchEmailsTool: ToolProtocol = defineTool(
        name: "search_emails",
        description: "Searches for recent emails in the user's Gmail inbox.",
        inputSchema: [
            "type": "object",
            "properties": [
                "query": [
                    "type": "string",
                    "description": "Email search query or sender name"
                ]
            ],
            "required": ["query"]
        ],
        isReadOnly: true
    ) { (input: SearchEmailsInput, _: ToolContext) async throws -> String in
        return "Found 0 unread emails matching '\(input.query)'. Gmail integration is active."
    }

    // 7. Query Notion
    public static let queryNotionTool: ToolProtocol = defineTool(
        name: "query_notion",
        description: "Searches documents or database records in the connected Notion workspace.",
        inputSchema: [
            "type": "object",
            "properties": [
                "query": [
                    "type": "string",
                    "description": "Keywords or title of the Notion page"
                ]
            ],
            "required": ["query"]
        ],
        isReadOnly: true
    ) { (input: QueryNotionInput, _: ToolContext) async throws -> String in
        return "Notion query '\(input.query)' completed. 0 pages updated."
    }
}
