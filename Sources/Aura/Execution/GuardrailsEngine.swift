import Foundation

/// Safety evaluation engine that classifies actions as safe to run or destructive requiring approval.
public final class GuardrailsEngine: Sendable {
    public static let shared = GuardrailsEngine()

    public init() {}

    private let destructivePatterns: [String] = [
        "rm ",
        "rm -",
        "rmdir",
        "unlink",
        "trash ",
        "rm -r",
        "rm -f",
        "rm -rf",
        "sudo ",
        "mkfs",
        "dd if=",
        "diskutil",
        "kill -9",
        "pkill",
        ":(){ :|:& };:",
        "chmod -R 777",
        "> /dev/sd",
        "git reset --hard",
        "git clean -fd"
    ]

    /// Evaluates whether a shell command requires human confirmation.
    public func evaluateCommand(_ command: String) -> CommandSafetyEvaluation {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        for pattern in destructivePatterns {
            if trimmed.contains(pattern) {
                return .requiresConfirmation(ActionConfirmationRequest(
                    title: "Destructive Command Detected",
                    description: "This command contains patterns that can permanently delete files or alter system privileges.",
                    commandOrAction: command,
                    riskLevel: .critical
                ))
            }
        }

        // Safe command
        return .safeToExecute
    }

    /// Generic tools are intentionally broad; policy belongs here, not in the model prompt.
    public func evaluateTool(name: String, input: [String: Any]) -> CommandSafetyEvaluation {
        switch name {
        case "terminal":
            let command = input["command"] as? String ?? ""
            return evaluateCommand(command)
        case "mac_script":
            let source = (input["source"] as? String ?? "").lowercased()
            // Flag destructive automation (e.g. deleting files via Finder or running destructive shell scripts)
            let destructiveAutomation = ["delete file", "delete folder", "delete every", "do shell script \"rm ", "do shell script \"sudo "]
            if destructiveAutomation.contains(where: { source.contains($0) }) {
                return confirmation(title: "Destructive automation needs approval", action: input["source"] as? String ?? "")
            }
            return .safeToExecute
        case "computer":
            return .safeToExecute
        default:
            return .safeToExecute
        }
    }

    private func confirmation(title: String, action: String) -> CommandSafetyEvaluation {
        .requiresConfirmation(ActionConfirmationRequest(
            title: title,
            description: "Aura prepared an action that can change your Mac or communicate with another app.",
            commandOrAction: action,
            riskLevel: .high
        ))
    }

    /// Evaluates whether an email action requires human confirmation.
    public func evaluateEmailSend(recipient: String, subject: String) -> CommandSafetyEvaluation {
        return .requiresConfirmation(ActionConfirmationRequest(
            title: "Send External Email",
            description: "Send email to \(recipient) with subject \"\(subject)\"",
            commandOrAction: "mailto:\(recipient)?subject=\(subject)",
            riskLevel: .medium
        ))
    }
}

public enum CommandSafetyEvaluation: Equatable, Sendable {
    case safeToExecute
    case requiresConfirmation(ActionConfirmationRequest)

    public var isSafe: Bool {
        if case .safeToExecute = self { return true }
        return false
    }
}
