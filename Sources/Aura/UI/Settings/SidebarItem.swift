import SwiftUI

/// Distinct navigation sections for the Aura Control Center sidebar.
public enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case chat = "Chat"
    case overview = "Overview"
    case models = "Models & AI"
    case voice = "Voice & Audio"
    case shortcuts = "Shortcuts"
    case connectors = "Connectors"
    case tools = "Tools"
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
        case .connectors: return "point.3.connected.trianglepath.dotted"
        case .tools: return "wrench.and.screwdriver.fill"
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
        case .connectors: return .cyan
        case .tools: return .blue
        case .appearance: return .pink
        }
    }
}
