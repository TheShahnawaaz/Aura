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
        let macControl = Skill(
            name: "mac_control",
            description: "Uses accessibility UI control, AppleScript/JXA, and terminal tools to operate macOS safely",
            userInvocable: true,
            promptTemplate: """
            Choose the narrowest native capability that fits the request.
            Use terminal for local shell and development work. Use mac_script for scriptable apps.
            For visible UI, call computer.observe before acting; element IDs expire after every observation.
            After each click, value change, keypress, or scroll, observe again and verify the intended result.
            Never claim a UI action succeeded without a fresh observation. Do not use terminal to invoke osascript.
            """
        )
        registry.register(macControl)

        let devInspection = Skill(
            name: "developer_inspection",
            description: "Proactively inspects files, shell environment, programming tools, and git status",
            userInvocable: true,
            promptTemplate: """
            When asked about development environment, code, files, or languages, run non-destructive terminal commands and summarize the observed result.
            """
        )
        registry.register(devInspection)

        let productivity = Skill(
            name: "productivity",
            description: "Automates productivity workflows, notes, reminders, and calendar tasks",
            userInvocable: true,
            promptTemplate: """
            Use native apps like Notes, Reminders, Calendar, and Safari to organize documents, tasks, and search.
            """
        )
        registry.register(productivity)

        // Discover and register skills from filesystem directories
        discoverExternalSkills()
    }

    private func discoverExternalSkills() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var searchDirs = [
            "\(home)/.aura/skills",
            "\(home)/Library/Application Support/Aura/Skills"
        ]
        searchDirs.append(contentsOf: SkillLoader.defaultSkillDirectories())

        let discovered = SkillLoader.discoverSkills(from: searchDirs)
        for skill in discovered {
            registry.register(skill)
        }
    }

    /// Returns a list of all registered skill names and descriptions.
    public func registeredSkillSummaries() -> [(name: String, description: String)] {
        registry.allSkills.map { ($0.name, $0.description) }
    }
}
