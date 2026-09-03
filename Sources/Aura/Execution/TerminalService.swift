import Foundation

/// Executes commands inside the user's interactive login shell (/bin/zsh -l -c).
public struct TerminalResult: Sendable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String

    public var isSuccess: Bool { exitCode == 0 }
}

public actor TerminalService {
    public static let shared = TerminalService()

    public init() {}

    /// Runs a command string inside a zsh login shell, preserving user environment variables and PATH.
    public func execute(
        command: String,
        currentDirectory: URL? = nil,
        timeoutSeconds: Double = 30.0
    ) async throws -> TerminalResult {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]

        if let currentDirectory {
            process.currentDirectoryURL = currentDirectory
        }

        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        // Wait with timeout
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while process.isRunning && Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        if process.isRunning {
            process.terminate()
            throw TerminalError.timeoutExceeded(timeoutSeconds)
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        let stdoutString = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderrString = String(data: stderrData, encoding: .utf8) ?? ""

        return TerminalResult(
            exitCode: process.terminationStatus,
            stdout: stdoutString,
            stderr: stderrString
        )
    }
}

public enum TerminalError: LocalizedError {
    case timeoutExceeded(Double)

    public var errorDescription: String? {
        switch self {
        case .timeoutExceeded(let seconds):
            return "Command execution timed out after \(seconds) seconds."
        }
    }
}
