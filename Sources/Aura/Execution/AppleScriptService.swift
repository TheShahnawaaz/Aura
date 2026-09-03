import Foundation

/// Executes AppleScript and JXA to orchestrate native macOS applications.
public actor AppleScriptService {
    public static let shared = AppleScriptService()

    public init() {}

    /// Executes an AppleScript script string and returns the string output or throws an error.
    public func execute(script: String) throws -> String {
        var errorDict: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else {
            throw AppleScriptError.compilationFailed("Failed to initialize NSAppleScript")
        }

        let result = scriptObject.executeAndReturnError(&errorDict)
        if let errorDict {
            let message = errorDict[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
            throw AppleScriptError.executionFailed(message)
        }

        return result.stringValue ?? ""
    }

    /// Executes either AppleScript in-process or JavaScript for Automation through osascript.
    /// JXA source is passed on stdin so it is never interpolated into a shell command.
    public func execute(language: String, source: String) async throws -> String {
        switch language.lowercased() {
        case "applescript", "apple-script":
            return try execute(script: source)
        case "javascript", "jxa":
            let process = Process()
            let input = Pipe()
            let output = Pipe()
            let error = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-l", "JavaScript"]
            process.standardInput = input
            process.standardOutput = output
            process.standardError = error
            try process.run()
            input.fileHandleForWriting.write(Data(source.utf8))
            try input.fileHandleForWriting.close()
            process.waitUntilExit()
            let stderr = String(decoding: error.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            guard process.terminationStatus == 0 else {
                throw AppleScriptError.executionFailed(stderr.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        default:
            throw AppleScriptError.executionFailed("Unsupported script language: \(language)")
        }
    }

    /// Opens an application by name.
    public func openApp(named appName: String) throws {
        let script = "tell application \"\(appName)\" to activate"
        _ = try execute(script: script)
    }

    /// Reveals a file in Finder.
    public func revealInFinder(path: String) throws {
        let script = "tell application \"Finder\" to reveal POSIX file \"\(path)\""
        _ = try execute(script: script)
    }
}

public enum AppleScriptError: LocalizedError {
    case compilationFailed(String)
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .compilationFailed(let reason):
            return "AppleScript compilation failed: \(reason)"
        case .executionFailed(let reason):
            return "AppleScript execution failed: \(reason)"
        }
    }
}
