import SwiftUI

/// Unified Capabilities Hub combining Native Tools, Domain Skills, and MCP Connectors.
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
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Capabilities")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Manage Aura's local primitives, specialized domain workflows, and external protocol connectors.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Segmented Tab Picker
                    Picker("", selection: $selectedTab) {
                        ForEach(CapabilityTab.allCases) { tab in
                            Label(tab.rawValue, systemImage: tab.iconName)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 460)

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
                .padding(28)
            }
        }
    }
}
