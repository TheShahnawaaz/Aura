import Foundation
import SwiftUI
import Combine

/// Central manager and persistence coordinator for Aura's tools, skills, and capabilities.
@MainActor
public final class CapabilityConfigManager: ObservableObject {
    public static let shared = CapabilityConfigManager()

    // MARK: - Native Tool Master Toggles
    @Published public var isComputerEnabled: Bool {
        didSet { UserDefaults.standard.set(isComputerEnabled, forKey: "cap_tool_computer_enabled") }
    }
    @Published public var isTerminalEnabled: Bool {
        didSet { UserDefaults.standard.set(isTerminalEnabled, forKey: "cap_tool_terminal_enabled") }
    }
    @Published public var isMacScriptEnabled: Bool {
        didSet { UserDefaults.standard.set(isMacScriptEnabled, forKey: "cap_tool_mac_script_enabled") }
    }
    @Published public var isWebEnabled: Bool {
        didSet { UserDefaults.standard.set(isWebEnabled, forKey: "cap_web_tools_enabled") }
    }
    @Published public var isFileSystemEnabled: Bool {
        didSet { UserDefaults.standard.set(isFileSystemEnabled, forKey: "cap_filesystem_tools_enabled") }
    }
    @Published public var isVisionEnabled: Bool {
        didSet { UserDefaults.standard.set(isVisionEnabled, forKey: "cap_vision_tools_enabled") }
    }

    // MARK: - Computer Sub-Action Permissions
    @Published public var allowObserve: Bool {
        didSet { UserDefaults.standard.set(allowObserve, forKey: "cap_computer_allow_observe") }
    }
    @Published public var allowClickAndType: Bool {
        didSet { UserDefaults.standard.set(allowClickAndType, forKey: "cap_computer_allow_click_type") }
    }
    @Published public var allowShortcuts: Bool {
        didSet { UserDefaults.standard.set(allowShortcuts, forKey: "cap_computer_allow_shortcuts") }
    }
    @Published public var allowScreenshots: Bool {
        didSet { UserDefaults.standard.set(allowScreenshots, forKey: "cap_computer_allow_screenshots") }
    }

    // MARK: - Mac Script Sub-Action Permissions
    @Published public var allowAppleScript: Bool {
        didSet { UserDefaults.standard.set(allowAppleScript, forKey: "cap_mac_script_allow_applescript") }
    }
    @Published public var allowJXA: Bool {
        didSet { UserDefaults.standard.set(allowJXA, forKey: "cap_mac_script_allow_jxa") }
    }

    // MARK: - Skills Management (Disabled Skill Names)
    // Storing disabled skill names ensures newly added skills are enabled by default
    @Published public var disabledSkills: Set<String> {
        didSet {
            let array = Array(disabledSkills)
            UserDefaults.standard.set(array, forKey: "cap_disabled_skills")
        }
    }

    private init() {
        let defaults = UserDefaults.standard

        // Tools defaults (default to true)
        self.isComputerEnabled = defaults.object(forKey: "cap_tool_computer_enabled") as? Bool ?? true
        self.isTerminalEnabled = defaults.object(forKey: "cap_tool_terminal_enabled") as? Bool ?? true
        self.isMacScriptEnabled = defaults.object(forKey: "cap_tool_mac_script_enabled") as? Bool ?? true
        self.isWebEnabled = defaults.object(forKey: "cap_web_tools_enabled") as? Bool ?? true
        self.isFileSystemEnabled = defaults.object(forKey: "cap_filesystem_tools_enabled") as? Bool ?? true
        self.isVisionEnabled = defaults.object(forKey: "cap_vision_tools_enabled") as? Bool ?? true

        // Computer sub-actions (default to true)
        self.allowObserve = defaults.object(forKey: "cap_computer_allow_observe") as? Bool ?? true
        self.allowClickAndType = defaults.object(forKey: "cap_computer_allow_click_type") as? Bool ?? true
        self.allowShortcuts = defaults.object(forKey: "cap_computer_allow_shortcuts") as? Bool ?? true
        self.allowScreenshots = defaults.object(forKey: "cap_computer_allow_screenshots") as? Bool ?? true

        // Mac script sub-actions (default to true)
        self.allowAppleScript = defaults.object(forKey: "cap_mac_script_allow_applescript") as? Bool ?? true
        self.allowJXA = defaults.object(forKey: "cap_mac_script_allow_jxa") as? Bool ?? true

        // Skills (default empty set of disabled skills)
        if let saved = defaults.stringArray(forKey: "cap_disabled_skills") {
            self.disabledSkills = Set(saved)
        } else {
            self.disabledSkills = []
        }
    }

    // MARK: - Query Helpers

    /// Checks if a generic tool is enabled.
    public func isToolEnabled(_ name: String) -> Bool {
        switch name.lowercased() {
        case "computer": return isComputerEnabled
        case "terminal", "execute_terminal_command": return isTerminalEnabled
        case "mac_script": return isMacScriptEnabled
        case "webfetch", "websearch": return isWebEnabled
        case "read", "write", "edit", "glob", "grep": return isFileSystemEnabled
        case "view_image", "vision": return isVisionEnabled
        default: return true
        }
    }

    /// Validates whether a specific sub-action for a tool is allowed.
    public func isSubActionAllowed(tool: String, action: String) -> (allowed: Bool, reason: String?) {
        switch tool.lowercased() {
        case "computer":
            guard isComputerEnabled else {
                return (false, "The computer tool is currently disabled in Capabilities Settings.")
            }
            switch action.lowercased() {
            case "observe":
                return allowObserve ? (true, nil) : (false, "Observing UI elements is disabled in Capabilities Settings.")
            case "click", "set_value":
                return allowClickAndType ? (true, nil) : (false, "Clicking and text input are disabled in Capabilities Settings.")
            case "press_key", "scroll":
                return allowShortcuts ? (true, nil) : (false, "Keyboard shortcuts and scrolling are disabled in Capabilities Settings.")
            case "screenshot":
                return allowScreenshots ? (true, nil) : (false, "Screenshot capture is disabled in Capabilities Settings.")
            default:
                return (true, nil)
            }

        case "mac_script":
            guard isMacScriptEnabled else {
                return (false, "The mac_script tool is currently disabled in Capabilities Settings.")
            }
            switch action.lowercased() {
            case "applescript", "apple-script":
                return allowAppleScript ? (true, nil) : (false, "AppleScript execution is disabled in Capabilities Settings.")
            case "javascript", "jxa":
                return allowJXA ? (true, nil) : (false, "JavaScript for Automation (JXA) execution is disabled in Capabilities Settings.")
            default:
                return (true, nil)
            }

        case "terminal", "execute_terminal_command":
            guard isTerminalEnabled else {
                return (false, "The terminal tool is currently disabled in Capabilities Settings.")
            }
            return (true, nil)

        default:
            return (true, nil)
        }
    }

    /// Checks if a skill is enabled.
    public func isSkillEnabled(_ name: String) -> Bool {
        !disabledSkills.contains(name)
    }

    /// Toggles a skill's enabled state.
    public func toggleSkill(_ name: String) {
        if disabledSkills.contains(name) {
            disabledSkills.remove(name)
        } else {
            disabledSkills.insert(name)
        }
    }

    /// Enables a skill explicitly.
    public func setSkillEnabled(_ name: String, isEnabled: Bool) {
        if isEnabled {
            disabledSkills.remove(name)
        } else {
            disabledSkills.insert(name)
        }
    }

    /// Total count of active capabilities.
    public var activeToolCount: Int {
        var count = 0
        if isComputerEnabled { count += 1 }
        if isTerminalEnabled { count += 1 }
        if isMacScriptEnabled { count += 1 }
        if isWebEnabled { count += 1 }
        if isFileSystemEnabled { count += 1 }
        if isVisionEnabled { count += 1 }
        return count
    }
}
