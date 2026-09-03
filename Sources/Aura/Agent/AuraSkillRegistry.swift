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

    /// Returns an active SkillRegistry containing only skills enabled in CapabilityConfigManager.
    @MainActor
    public func activeSkillsRegistry() -> SkillRegistry {
        let activeReg = SkillRegistry()
        for skill in registry.allSkills {
            if CapabilityConfigManager.shared.isSkillEnabled(skill.name) {
                activeReg.register(skill)
            }
        }
        return activeReg
    }

    /// Reloads all skills: re-registers domain skills and re-scans filesystem directories.
    public func reloadSkills() {
        // Re-discover external skills
        discoverExternalSkills()
    }

    /// Ensures the ~/.aura/skills folder exists on disk and returns its path.
    @discardableResult
    public func ensureSkillsFolderExists() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let skillsDir = "\(home)/.aura/skills"
        let fm = FileManager.default
        if !fm.fileExists(atPath: skillsDir) {
            try? fm.createDirectory(atPath: skillsDir, withIntermediateDirectories: true)
            // Drop a sample README explaining how to add custom skills
            let readme = """
            # Aura Custom Skills Directory

            Drop your custom skill folders here! Each skill should be a subfolder containing a `SKILL.md` file.

            Example structure:
            ~/.aura/skills/
              └── my_custom_skill/
                  └── SKILL.md

            Example SKILL.md frontmatter:
            ---
            name: my_custom_skill
            description: Description of what this skill does
            user_invocable: true
            ---
            Your skill instructions and prompt template go here.
            """
            let readmePath = "\(skillsDir)/README.md"
            try? readme.write(toFile: readmePath, atomically: true, encoding: .utf8)
        }
        return skillsDir
    }

    /// Returns a list of all registered skill names and descriptions.
    public func registeredSkillSummaries() -> [(name: String, description: String)] {
        registry.allSkills.map { ($0.name, $0.description) }
    }
}
