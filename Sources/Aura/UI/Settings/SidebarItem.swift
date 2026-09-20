import SwiftUI

/// Semantic categorical grouping for the Control Center sidebar.
public enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case workspace = "Workspace"
    case intelligence = "Intelligence"
    case system = "System"

    public var id: String { rawValue }
    public var title: String { rawValue.uppercased() }

    public var items: [SidebarItem] {
        switch self {
        case .workspace:
            return [.chat, .overview]
        case .intelligence:
            return [.models, .capabilities]
        case .system:
            return [.voice, .shortcuts, .permissions, .appearance]
        }
    }
}

/// Distinct navigation sections for the Aura Control Center sidebar.
public enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case chat = "Chat"
    case overview = "Overview"
    case models = "Models & AI"
    case capabilities = "Capabilities"
    case voice = "Voice & Audio"
    case shortcuts = "Shortcuts"
    case permissions = "Permissions"
    case appearance = "Appearance"

    public var id: String { rawValue }
    public var title: String { rawValue }

    public var subtitle: String {
        switch self {
        case .chat: return "Agent & Tool Conversation"
        case .overview: return "Telemetry & Core Status"
        case .models: return "LLM Providers & API Keys"
        case .capabilities: return "Tools & Computer Control"
        case .voice: return "Speech & Audio Pipeline"
        case .shortcuts: return "Global Hotkeys & Triggers"
        case .permissions: return "System Privacy & Grants"
        case .appearance: return "Notch HUD & Material Finish"
        }
    }

    public var shortcutIndex: Int {
        switch self {
        case .chat: return 1
        case .overview: return 2
        case .models: return 3
        case .capabilities: return 4
        case .voice: return 5
        case .shortcuts: return 6
        case .permissions: return 7
        case .appearance: return 8
        }
    }

    public var shortcutString: String {
        "⌘\(shortcutIndex)"
    }

    public var iconName: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .overview: return "gauge.with.needle.fill"
        case .models: return "brain.head.profile"
        case .capabilities: return "wrench.and.screwdriver.fill"
        case .voice: return "waveform"
        case .shortcuts: return "keyboard"
        case .permissions: return "lock.shield.fill"
        case .appearance: return "sparkles"
        }
    }

    public var iconColor: Color {
        switch self {
        case .chat: return ControlCenterTokens.Colors.accentIris
        case .overview: return ControlCenterTokens.Colors.accentCyan
        case .models: return ControlCenterTokens.Colors.accentPurple
        case .capabilities: return ControlCenterTokens.Colors.accentIndigo
        case .voice: return ControlCenterTokens.Colors.accentAmber
        case .shortcuts: return ControlCenterTokens.Colors.accentEmerald
        case .permissions: return ControlCenterTokens.Colors.accentCoral
        case .appearance: return Color.pink
        }
    }
}

