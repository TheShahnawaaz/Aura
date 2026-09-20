import SwiftUI

/// Main Control Center & Settings interface for Aura.
/// Crafted according to Apple HIG and swiftui-design-skill principles:
/// - Native macOS window layout with integrated traffic-light alignment
/// - Categorized semantic sidebar (Workspace, Intelligence, System)
/// - Hardware-accelerated keyboard navigation (⌘1–⌘8)
/// - Unified obsidian liquid-glass material hierarchy with 0.5pt specular hairlines
/// - Real-time system telemetry and model indicators in the unified header
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
            // MARK: - Unified Control Center Top Header Bar
            unifiedTopHeader
                .zIndex(20)

            // Specular 0.5pt Hairline Divider
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
                .frame(height: ControlCenterTokens.Stroke.hairline)
                .zIndex(20)

            // MARK: - Main Horizontal Workspace
            HStack(spacing: 0) {
                // Sidebar Column with native smooth spring collapse
                HStack(spacing: 0) {
                    sidebarView
                        .frame(width: isSidebarCollapsed ? 56 : 228)
                        .animation(ControlCenterTokens.Motion.fluid, value: isSidebarCollapsed)

                    // Specular Vertical Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.04),
                                    Color.white.opacity(0.01)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: ControlCenterTokens.Stroke.hairline)
                }
                .zIndex(10)

                // Detail Panel
                ZStack {
                    ControlCenterTokens.Colors.windowBackdrop
                        .ignoresSafeArea()

                    // Subtle top ambient glow keyed to active tab color
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
                        .frame(height: 220)
                        .allowsHitTesting(false)

                        Spacer()
                    }

                    detailPanel
                }
                .frame(minWidth: 600, minHeight: 480)
            }
        }
        .background(ControlCenterTokens.Colors.windowBackdrop)
        .overlay(
            // Subtle ambient top specular rim
            LinearGradient(
                colors: [
                    ControlCenterTokens.Colors.accentIris.opacity(0.35),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 1.5)
            .allowsHitTesting(false),
            alignment: .top
        )
        .preferredColorScheme(.dark)
        .frame(minWidth: 860, minHeight: 540)
        .ignoresSafeArea()
        // MARK: - Global Keyboard Shortcuts (⌘1 through ⌘8)
        .background {
            Group {
                Button("") { appState.activeSidebarTab = .chat }.keyboardShortcut("1", modifiers: .command)
                Button("") { appState.activeSidebarTab = .overview }.keyboardShortcut("2", modifiers: .command)
                Button("") { appState.activeSidebarTab = .models }.keyboardShortcut("3", modifiers: .command)
                Button("") { appState.activeSidebarTab = .capabilities }.keyboardShortcut("4", modifiers: .command)
                Button("") { appState.activeSidebarTab = .voice }.keyboardShortcut("5", modifiers: .command)
                Button("") { appState.activeSidebarTab = .shortcuts }.keyboardShortcut("6", modifiers: .command)
                Button("") { appState.activeSidebarTab = .permissions }.keyboardShortcut("7", modifiers: .command)
                Button("") { appState.activeSidebarTab = .appearance }.keyboardShortcut("8", modifiers: .command)
            }
            .opacity(0)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Unified Header Bar
    private var unifiedTopHeader: some View {
        HStack(spacing: 12) {
            // Traffic lights clearance + Sidebar Toggle Button
            HStack(spacing: 8) {
                // macOS native close/min/zoom sit at x: ~18-68
                Spacer()
                    .frame(width: 68)

                // Sidebar Toggle Button
                Button {
                    withAnimation(ControlCenterTokens.Motion.fluid) {
                        isSidebarCollapsed.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.leading")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(.white.opacity(isSidebarCollapsed ? 0.50 : 0.85))
                        .frame(width: 28, height: 26)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(ControlCenterTokens.Radii.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.button, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: ControlCenterTokens.Stroke.hairline)
                        )
                }
                .buttonStyle(.plain)
                .help(isSidebarCollapsed ? "Expand Sidebar (⌘B)" : "Collapse Sidebar (⌘B)")
            }

            // Specular vertical separator tick
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: ControlCenterTokens.Stroke.hairline, height: 16)

            // High-Craft Breadcrumb Trail
            HStack(spacing: 6) {
                Text("Aura")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.40))

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))

                Text(currentSectionTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))

                Text(currentBreadcrumbTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Far-Right Controls
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
        HStack(spacing: 8) {
            // Chat Threads Pane Toggle
            Button {
                withAnimation(ControlCenterTokens.Motion.fluid) {
                    isChatThreadsVisible.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 11, weight: .medium))
                    Text(isChatThreadsVisible ? "Hide Threads" : "Threads")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isChatThreadsVisible ? ControlCenterTokens.Colors.accentIris.opacity(0.22) : Color.white.opacity(0.05))
                .foregroundColor(isChatThreadsVisible ? ControlCenterTokens.Colors.accentIris : .white.opacity(0.65))
                .cornerRadius(ControlCenterTokens.Radii.button)
                .overlay(
                    RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.button, style: .continuous)
                        .strokeBorder(isChatThreadsVisible ? ControlCenterTokens.Colors.accentIris.opacity(0.35) : Color.white.opacity(0.08), lineWidth: ControlCenterTokens.Stroke.hairline)
                )
            }
            .buttonStyle(.plain)
            .help(isChatThreadsVisible ? "Hide Conversation Threads" : "Show Conversation Threads")

            // Active Model Badge / Switcher
            Button {
                withAnimation(ControlCenterTokens.Motion.snappy) {
                    appState.activeSidebarTab = .models
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundColor(ControlCenterTokens.Colors.accentIris)

                    Text(LLMService.shared.activeModelName)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.80))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05))
                .cornerRadius(ControlCenterTokens.Radii.button)
                .overlay(
                    RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.button, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: ControlCenterTokens.Stroke.hairline)
                )
            }
            .buttonStyle(.plain)
            .help("Active LLM model (Click to configure in Models & AI)")

            // Clear Thread Button
            Button {
                withAnimation(ControlCenterTokens.Motion.snappy) {
                    sessionManager.deleteSession(id: sessionManager.activeSession.id)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 10.5))
                    Text("Clear")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05))
                .foregroundColor(.white.opacity(0.65))
                .cornerRadius(ControlCenterTokens.Radii.button)
                .overlay(
                    RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.button, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: ControlCenterTokens.Stroke.hairline)
                )
            }
            .buttonStyle(.plain)
            .help("Clear messages in this thread")
        }
    }

    // MARK: - Default Header Controls
    private var defaultTopBarControls: some View {
        HStack(spacing: 8) {
            // Live Status Pill
            HStack(spacing: 5) {
                Circle()
                    .fill(appState.state == .idle ? Color.white.opacity(0.40) : ControlCenterTokens.Colors.accentEmerald)
                    .frame(width: 5, height: 5)
                    .shadow(color: appState.state == .idle ? Color.clear : ControlCenterTokens.Colors.accentEmerald.opacity(0.6), radius: 3)

                Text(appState.state == .idle ? "READY" : "ACTIVE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(appState.state == .idle ? .white.opacity(0.55) : ControlCenterTokens.Colors.accentEmerald)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(Color.white.opacity(0.05))
            .cornerRadius(ControlCenterTokens.Radii.button)
            .overlay(
                RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.button, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: ControlCenterTokens.Stroke.hairline)
            )

            // Global Trigger Keycap
            ControlCenterKeycapView(appState.hotkeyDisplayString, fontSize: 9.5)
                .help("Global HUD activation hotkey")
        }
    }

    private var currentSectionTitle: String {
        for section in SidebarSection.allCases {
            if section.items.contains(appState.activeSidebarTab) {
                return section.rawValue
            }
        }
        return "Control Center"
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
                // Expanded Header: Brand Title & Telemetry Orb
                HStack(spacing: 10) {
                    LivingAuroraOrbView(appState: appState, size: 22, showSquircleBackground: false)

                    VStack(alignment: .leading, spacing: 1.5) {
                        HStack(spacing: 5) {
                            Text("AURA")
                                .font(.system(size: 12.5, weight: .black, design: .rounded))
                                .tracking(1.4)
                                .foregroundColor(.white)

                            Text("v\(AuraVersion.current)")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(ControlCenterTokens.Colors.accentIris)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(ControlCenterTokens.Colors.accentIris.opacity(0.15))
                                .cornerRadius(3.5)
                        }

                        Text("Desktop Control Center")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.42))
                    }

                    Spacer()
                }
                .padding(.top, 14)
                .padding(.horizontal, 14)
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

            // Categorized Navigation Items List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(SidebarSection.allCases) { section in
                        VStack(alignment: .leading, spacing: 3) {
                            if !isSidebarCollapsed {
                                Text(section.title)
                                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                    .tracking(0.9)
                                    .foregroundColor(.white.opacity(0.32))
                                    .padding(.horizontal, 10)
                                    .padding(.top, 4)
                                    .padding(.bottom, 2)
                            } else {
                                Divider()
                                    .overlay(Color.white.opacity(0.04))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                            }

                            ForEach(section.items) { item in
                                sidebarRow(for: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, isSidebarCollapsed ? 8 : 10)
                .padding(.bottom, 12)
            }

            Spacer()

            // Footer
            VStack(spacing: 6) {
                Divider()
                    .overlay(Color.white.opacity(0.06))

                if !isSidebarCollapsed {
                    HStack {
                        VStack(alignment: .leading, spacing: 1.5) {
                            Text("NOTCH HUD")
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.30))
                            Text("Global Trigger")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.58))
                        }

                        Spacer()

                        ControlCenterKeycapView(appState.hotkeyDisplayString, fontSize: 9.5)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                } else {
                    ControlCenterKeycapView("⌥", fontSize: 9.5)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .background(
            ZStack {
                Color(red: 0.038, green: 0.040, blue: 0.048)
                ControlCenterTokens.Colors.sidebarBackdrop
            }
        )
    }

    @ViewBuilder
    private func sidebarRow(for item: SidebarItem) -> some View {
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

    // MARK: - Detail Content Panel
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
        case .capabilities:
            CapabilitiesSettingsView()
                .transition(.opacity)
        case .voice:
            VoiceAudioSettingsView(appState: appState)
                .transition(.opacity)
        case .shortcuts:
            ShortcutsSettingsView(appState: appState)
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
