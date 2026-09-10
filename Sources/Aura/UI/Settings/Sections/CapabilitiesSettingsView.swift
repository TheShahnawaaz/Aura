import SwiftUI

/// Unified Capabilities Hub combining Native Tools, Domain Skills, and MCP Connectors,
/// styled with obsidian liquid-glass design.
public struct CapabilitiesSettingsView: View {
    @State private var selectedTab: CapabilityTab = .tools
    @ObservedObject private var capabilityConfig = CapabilityConfigManager.shared

    public init() {}

    public enum CapabilityTab: String, CaseIterable, Identifiable {
        case tools = "Tools"
        case skills = "Skills"
        case connectors = "Connectors & MCP"

        public var id: String { rawValue }

        var iconName: String {
            switch self {
            case .tools: return "wrench.and.screwdriver"
            case .skills: return "sparkles"
            case .connectors: return "point.3.connected.trianglepath.dotted"
            }
        }
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capabilities Hub")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Manage Aura's local execution primitives, specialized domain workflows, and external MCP servers.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                // Liquid-Glass Tab Bar
                ControlCenterLiquidTabBar(
                    selectedTab: $selectedTab,
                    tabs: CapabilityTab.allCases,
                    titleForTab: { $0.rawValue },
                    iconForTab: { $0.iconName }
                )

                // Tab Content
                switch selectedTab {
                case .tools:
                    ToolsSettingsView()
                case .skills:
                    SkillsSettingsView()
                case .connectors:
                    ConnectorsSettingsView()
                }
            }
            .padding(24)
        }
    }
}
