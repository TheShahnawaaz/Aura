import SwiftUI

/// Main Control Center & Settings interface for Aura with an Antigravity-style unified window chrome,
/// collapsible icon-rail sidebar, inline breadcrumbs, and multi-panel navigation.
public struct SettingsView: View {
    @ObservedObject public var appState: AppState = .shared
    @ObservedObject private var sessionManager = AgentSessionManager.shared

    @State private var isSidebarCollapsed: Bool = false
    @State private var isChatThreadsVisible: Bool = true

    public init(appState: AppState = .shared) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Unified Antigravity Top Header Bar
            unifiedTopHeader
                .zIndex(20)

            // Specular Hairline Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.01)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .zIndex(20)

            // MARK: - Main Horizontal Workspace
            HStack(spacing: 0) {
                // Sidebar Column (Elevated surface: slides drawers under itself)
                HStack(spacing: 0) {
                    sidebarView
                        .frame(width: isSidebarCollapsed ? 54 : 230)
                        .animation(ControlCenterTokens.Motion.fluid, value: isSidebarCollapsed)

                    // Specular Vertical Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.14),
                                    Color.white.opacity(0.04),
                                    Color.white.opacity(0.01)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1)
                }
                .zIndex(10)
                .shadow(color: Color.black.opacity(0.40), radius: 8, x: 3, y: 0)

                // Detail Panel (Underneath main sidebar z-order)
                ZStack {
                    ControlCenterTokens.Colors.windowBackdrop
                        .ignoresSafeArea()

                    // Subtle ambient top glow
                    VStack {
                        RadialGradient(
                            colors: [
                                appState.activeSidebarTab.iconColor.opacity(0.06),
                                Color.clear
                            ],
                            center: .top,
                            startRadius: 0,
                            endRadius: 360
                        )
                        .frame(height: 240)
                        .allowsHitTesting(false)

                        Spacer()
                    }

                    detailPanel
                }
                .frame(minWidth: 560, minHeight: 480)
            }
        }
        .background(ControlCenterTokens.Colors.windowBackdrop)
        .overlay(
            // Subtle ambient top border specular rim matching Antigravity
            LinearGradient(
                colors: [
                    ControlCenterTokens.Colors.accentIndigo.opacity(0.40),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 2)
            .allowsHitTesting(false),
            alignment: .top
        )
        .preferredColorScheme(.dark)
        .frame(minWidth: 840, minHeight: 520)
        .ignoresSafeArea()
    }

    // MARK: - Unified Antigravity Top Header Bar
    private var unifiedTopHeader: some View {
        HStack(spacing: 12) {
            // Traffic lights clearance + Sidebar Toggle Button
            HStack(spacing: 8) {
                // macOS native close/min/zoom sit at x: ~18-68
                Spacer()
                    .frame(width: 66)

                // Sidebar Toggle Button
                Button {
                    withAnimation(ControlCenterTokens.Motion.fluid) {
                        isSidebarCollapsed.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.leading")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(isSidebarCollapsed ? 0.45 : 0.85))
                        .frame(width: 28, height: 26)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help(isSidebarCollapsed ? "Expand Sidebar" : "Collapse Sidebar")
            }

            // Specular vertical separator tick
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 16)

            // Breadcrumbs: Aura / Section Title (or Thread Title)
            HStack(spacing: 8) {
                Text("Aura")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))

                Text("/")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.25))

                Text(currentBreadcrumbTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Far-right Header Controls
            if appState.activeSidebarTab == .chat {
                chatTopBarControls
            } else {
                defaultTopBarControls
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(ControlCenterTokens.Colors.sidebarBackdrop)
    }

    // MARK: - Chat Header Controls
    private var chatTopBarControls: some View {
        HStack(spacing: 10) {
            // Chat Threads Pane Toggle
            Button {
                withAnimation(ControlCenterTokens.Motion.fluid) {
                    isChatThreadsVisible.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 11, weight: .semibold))
                    Text(isChatThreadsVisible ? "Hide Threads" : "Show Threads")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isChatThreadsVisible ? ControlCenterTokens.Colors.accentIndigo.opacity(0.25) : Color.white.opacity(0.06))
                .foregroundColor(isChatThreadsVisible ? ControlCenterTokens.Colors.accentIndigo : .white.opacity(0.55))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isChatThreadsVisible ? ControlCenterTokens.Colors.accentIndigo.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help(isChatThreadsVisible ? "Hide Conversation Threads" : "Show Conversation Threads")

            // Active Model Badge
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9))
                    .foregroundColor(ControlCenterTokens.Colors.accentIndigo)

                Text(LLMService.shared.activeModelName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.06))
            .cornerRadius(6)

            // Clear Thread Button
            Button {
                withAnimation {
                    sessionManager.deleteSession(id: sessionManager.activeSession.id)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                    Text("Clear")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .foregroundColor(.white.opacity(0.65))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Clear messages in this thread")
        }
    }

    // MARK: - Default Header Controls
    private var defaultTopBarControls: some View {
        HStack(spacing: 8) {
            // Live Status Pill
            HStack(spacing: 4) {
                Circle()
                    .fill(appState.state == .idle ? Color.white.opacity(0.4) : ControlCenterTokens.Colors.accentEmerald)
                    .frame(width: 5, height: 5)

                Text(appState.state == .idle ? "Ready" : "Active")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(appState.state == .idle ? .white.opacity(0.5) : ControlCenterTokens.Colors.accentEmerald)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(Color.white.opacity(0.06))
            .cornerRadius(4)

            // Global Trigger Keycap
            ControlCenterKeycapView(appState.hotkeyDisplayString, fontSize: 10)
        }
    }

    private var currentBreadcrumbTitle: String {
        if appState.activeSidebarTab == .chat {
            return sessionManager.activeSession.title
        }
        return appState.activeSidebarTab.title
    }

    // MARK: - Sidebar View
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isSidebarCollapsed {
                // Expanded Header: Brand Title
                HStack(spacing: 10) {
                    LivingAuroraOrbView(appState: appState, size: 20, showSquircleBackground: false)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("AURA")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(.white)

                        Text("Control Center")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }

                    Spacer()
                }
                .padding(.top, 14)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            } else {
                // Collapsed Mini Header: Just the Living Orb
                HStack {
                    Spacer()
                    LivingAuroraOrbView(appState: appState, size: 22, showSquircleBackground: false)
                        .padding(.top, 14)
                        .padding(.bottom, 12)
                    Spacer()
                }
            }

            // Navigation Items List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 3) {
                    ForEach(SidebarItem.allCases) { item in
                        ControlCenterSidebarRow(
                            item: item,
                            isSelected: appState.activeSidebarTab == item,
                            isCollapsed: isSidebarCollapsed
                        ) {
                            withAnimation(ControlCenterTokens.Motion.snappy) {
                                appState.activeSidebarTab = item
                            }
                        }
                    }
                }
                .padding(.horizontal, isSidebarCollapsed ? 8 : 10)
            }

            Spacer()

            // Footer
            VStack(spacing: 8) {
                Divider()
                    .overlay(Color.white.opacity(0.06))

                if !isSidebarCollapsed {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GLOBAL TRIGGER")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.35))
                            Text("Toggle HUD anywhere")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }

                        Spacer()

                        ControlCenterKeycapView(appState.hotkeyDisplayString, fontSize: 10)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                } else {
                    ControlCenterKeycapView("⌥", fontSize: 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .background(
            ZStack {
                Color(red: 0.040, green: 0.042, blue: 0.052)
                ControlCenterTokens.Colors.sidebarBackdrop
            }
        )
    }

    // MARK: - Detail Content
    @ViewBuilder
    private var detailPanel: some View {
        switch appState.activeSidebarTab {
        case .chat:
            ChatPanelSettingsView(appState: appState, isThreadListVisible: $isChatThreadsVisible)
                .transition(.opacity)
        case .overview:
            OverviewDashboardView(appState: appState)
                .transition(.opacity)
        case .models:
            ModelsAISettingsView()
                .transition(.opacity)
        case .voice:
            VoiceAudioSettingsView(appState: appState)
                .transition(.opacity)
        case .shortcuts:
            ShortcutsSettingsView(appState: appState)
                .transition(.opacity)
        case .capabilities:
            CapabilitiesSettingsView()
                .transition(.opacity)
        case .permissions:
            PermissionsSettingsView()
                .transition(.opacity)
        case .appearance:
            AppearanceSettingsView(appState: appState)
                .transition(.opacity)
        }
    }
}
