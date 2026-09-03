import SwiftUI

/// Distinct navigation sections for the Aura Control Center sidebar.
public enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case chat = "Chat"
    case overview = "Overview"
    case models = "Models & AI"
    case voice = "Voice & Audio"
    case shortcuts = "Shortcuts"
    case capabilities = "Capabilities"
    case permissions = "Permissions"
    case appearance = "Appearance"

    public var id: String { rawValue }

    public var title: String { rawValue }

    public var iconName: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .overview: return "gauge.with.needle.fill"
        case .models: return "brain.head.profile"
        case .voice: return "waveform"
        case .shortcuts: return "keyboard"
        case .capabilities: return "wrench.and.screwdriver.fill"
        case .permissions: return "lock.shield.fill"
        case .appearance: return "sparkles"
        }
    }

    public var iconColor: Color {
        switch self {
        case .chat: return .indigo
        case .overview: return .blue
        case .models: return .purple
        case .voice: return .orange
        case .shortcuts: return .green
        case .capabilities: return .blue
        case .permissions: return .teal
        case .appearance: return .pink
        }
    }
}
