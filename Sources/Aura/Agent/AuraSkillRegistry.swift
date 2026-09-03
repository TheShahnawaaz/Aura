import Foundation
import OpenAgentSDK

/// Central registry managing domain skills and workflows for Aura.
public final class AuraSkillRegistry: @unchecked Sendable {
    public static let shared = AuraSkillRegistry()

    public let registry: SkillRegistry

    private init() {
        self.registry = SkillRegistry()
        registerDomainSkills()
    }

    private func registerDomainSkills() {
        // 1. System Control Skill
        let systemControl = Skill(
            name: "system_control",
            description: "Controls macOS hardware and applications (volume, apps, screenshots)",
            promptTemplate: """
            When the user wants to control their Mac (open an app, adjust speaker volume, take a screenshot),
            use the respective native tools directly and provide concise, affirmative confirmation.
            """
        )
        registry.register(systemControl)

        // 2. Developer & Environment Inspection Skill
        let devInspection = Skill(
            name: "developer_inspection",
            description: "Proactively inspects files, shell environment, programming tools, and git status",
            promptTemplate: """
            When asked about development environment, code, files, or languages:
            1. Proactively run non-destructive shell commands (`which`, `brew list`, `ls -1`, `sw_vers`, `uname -a`).
            2. Inspect relevant directories before stating an answer.
            3. Synthesize the findings into a clear, direct summary.
            """
        )
        registry.register(devInspection)

        // 3. Workspace Productivity Skill
        let productivity = Skill(
            name: "productivity",
            description: "Searches Gmail and queries Notion databases",
            promptTemplate: """
            Use query_notion and search_emails when the user refers to past notes, documents, or inbox messages.
            """
        )
        registry.register(productivity)
    }
}
