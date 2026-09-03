import SwiftUI

/// Main Control Center & Settings interface for Aura with a full macOS sidebar and multi-panel navigation.
public struct SettingsView: View {
    @ObservedObject public var appState: AppState = .shared

    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    public init(appState: AppState = .shared) {
        self.appState = appState
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(SidebarItem.allCases, selection: $appState.activeSidebarTab) { item in
                NavigationLink(value: item) {
                    Label {
                        Text(item.title)
                            .font(.body.weight(.medium))
                    } icon: {
                        Image(systemName: item.iconName)
                            .foregroundColor(item.iconColor)
                    }
                }
            }
            .navigationTitle("Aura")
            .toolbar(removing: .sidebarToggle)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        withAnimation {
                            if columnVisibility == .detailOnly {
                                columnVisibility = .all
                            } else {
                                columnVisibility = .detailOnly
                            }
                        }
                    } label: {
                        Image(systemName: "sidebar.leading")
                    }
                    .help("Toggle Sidebar")
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            // Detail Panel
            Group {
                switch appState.activeSidebarTab {
                case .chat:
                    ChatPanelSettingsView(appState: appState)
                case .overview:
                    OverviewDashboardView(appState: appState)
                case .models:
                    ModelsAISettingsView()
                case .voice:
                    VoiceAudioSettingsView(appState: appState)
                case .shortcuts:
                    ShortcutsSettingsView(appState: appState)
                case .connectors:
                    ConnectorsSettingsView()
                case .tools:
                    ToolsSettingsView()
                case .permissions:
                    PermissionsSettingsView()
                case .appearance:
                    AppearanceSettingsView(appState: appState)
                }
            }
            .frame(minWidth: 540, minHeight: 480)
        }
        .frame(minWidth: 800, minHeight: 520)
    }
}
