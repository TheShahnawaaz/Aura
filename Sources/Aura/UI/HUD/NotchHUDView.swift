import SwiftUI

/// Main HUD overlay view that anchors directly to the MacBook camera notch and drops
/// down dynamically with liquid-glass spring physics.
public struct NotchHUDView: View {
    @ObservedObject public var appState: AppState
    @ObservedObject public var geometry: NotchGeometry
    @ObservedObject public var sessionManager = AgentSessionManager.shared

    @AppStorage("enableAmbientGlow") private var enableAmbientGlow: Bool = true
    @State private var isHovering: Bool = false
    @State private var hoverTask: Task<Void, Never>? = nil
    @State private var inspectorContentHeight: CGFloat = 0
    @Namespace private var orbNamespace

    public init(appState: AppState = .shared, geometry: NotchGeometry) {
        self.appState = appState
        self.geometry = geometry
    }

    // MARK: - Dynamic Sizing & State Computations
    private var isExpanded: Bool {
        if appState.state != .idle {
            return true
        }
        if appState.isTurnCompletedPresented {
            return true
        }
        return isHovering
    }

    private var isOrbDownInMessageArea: Bool {
        appState.state != .idle
    }

    private var targetWidth: CGFloat {
        if isExpanded {
            return max(geometry.closedWidth, HUDDesignTokens.Geometry.minExpandedWidth)
        }
        return geometry.closedWidth
    }

    private var targetHeight: CGFloat {
        if isExpanded {
            if (isHovering || appState.isTurnCompletedPresented) && appState.state == .idle {
                if inspectorContentHeight > 0 {
                    return min(620, geometry.notchHeight + inspectorContentHeight + 46)
                }
                let session = currentSelectedSession
                let hasTools = session?.messages.last?.toolCalls.isEmpty == false
                return hasTools ? geometry.notchHeight + 230 : geometry.notchHeight + 150
            }

            switch appState.state {
            case .listening:
                let textLength = appState.partialTranscript.count
                return textLength > 100 ? geometry.notchHeight + 132 : geometry.notchHeight + 104

            case .processing:
                return geometry.notchHeight + 108

            case .speaking(let text):
                let count = text.count
                let lineBreaks = text.components(separatedBy: "\n").count
                if count > 280 || lineBreaks >= 6 {
                    return min(340, geometry.notchHeight + 230)
                } else if count > 150 || lineBreaks >= 4 {
                    return geometry.notchHeight + 176
                } else if count > 65 || lineBreaks >= 2 {
                    return geometry.notchHeight + 136
                } else {
                    return geometry.notchHeight + 108
                }

            case .awaitingConfirmation:
                return geometry.notchHeight + 138

            case .error:
                return geometry.notchHeight + 92

            default:
                return geometry.notchHeight + 104
            }
        }
        return geometry.notchHeight
    }

    private var currentSelectedSession: ConversationSession? {
        if let id = sessionManager.selectedSessionId {
            return sessionManager.sessions.first(where: { $0.id == id })
        }
        return nil
    }

    private var stateColor: Color {
        switch appState.state {
        case .idle:
            return HUDDesignTokens.Colors.idleLilac
        case .listening:
            return HUDDesignTokens.Colors.listeningCyan
        case .processing:
            return HUDDesignTokens.Colors.processingViolet
        case .speaking:
            return HUDDesignTokens.Colors.speakingCoral
        case .awaitingConfirmation:
            return HUDDesignTokens.Colors.actionAmber
        case .error:
            return HUDDesignTokens.Colors.errorRed
        }
    }

    // MARK: - Main Body
    public var body: some View {
        VStack(spacing: 0) {
            // Top Notch Cap Bar (Left Ear | Physical Notch Spacer | Right Ear)
            notchCapBar
                .frame(height: geometry.notchHeight)

            // Dynamic Dropdown Body
            if isExpanded {
                expandedContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(width: targetWidth, height: targetHeight, alignment: .top)
        .background(hudBackground)
        .clipShape(hudNotchShape)
        .overlay(hudBorder)
        .shadow(color: Color.black.opacity(isExpanded ? 0.50 : 0.50), radius: isExpanded ? 24 : 9, y: isExpanded ? 12 : 3.5)
        .shadow(color: isExpanded ? stateColor.opacity(0.14) : Color.clear, radius: 18, y: 14)
        .contentShape(Rectangle())
        .onHover { handleHover($0) }
        .onPreferenceChange(ContentHeightPreferenceKey.self) { handleHeightChange($0) }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(HUDDesignTokens.Springs.fluid, value: isExpanded)
        .animation(HUDDesignTokens.Springs.fluid, value: targetHeight)
    }

    // MARK: - Notch Silhouette Shape
    private var hudNotchShape: NotchShape {
        NotchShape(
            topEarRadius: HUDDesignTokens.Geometry.closedEarRadius,
            bottomCornerRadius: isExpanded ? HUDDesignTokens.Geometry.expandedBottomCornerRadius : HUDDesignTokens.Geometry.closedBottomCornerRadius
        )
    }

    // MARK: - Background Architecture
    @ViewBuilder
    private var hudBackground: some View {
        ZStack {
            // True pitch-black base (#000000) - exact optical match to MacBook notch and iPhone Dynamic Island
            HUDDesignTokens.Colors.notchBlack

            // Rich obsidian liquid-glass depth layers (only active when expanded)
            if isExpanded {
                ZStack {
                    HUDDesignTokens.Colors.obsidianBase.opacity(0.85)

                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.35)

                    if enableAmbientGlow {
                        // Ambient state glow positioned in the lower card body, NEVER in the notch zone
                        RadialGradient(
                            colors: [
                                stateColor.opacity(0.20),
                                stateColor.opacity(0.05),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.5, y: 0.75),
                            startRadius: 10,
                            endRadius: 200
                        )
                        .animation(.easeInOut(duration: 0.35), value: appState.state)
                    }
                }
                // Mask: guarantees the top notch zone (y = 0..notchHeight) remains completely pure black
                .mask(
                    VStack(spacing: 0) {
                        // Top Notch Zone: 100% transparent mask, preserving pure black base
                        Color.clear
                            .frame(height: geometry.notchHeight)

                        // Smooth 24pt feather transition from black notch into glass dropdown
                        LinearGradient(
                            colors: [Color.clear, Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 24)

                        // Fully revealed glass body below
                        Color.white
                    }
                )
            }
        }
    }

    // MARK: - Specular Border Overlay
    private var hudBorder: some View {
        NotchBorderShape(
            topEarRadius: HUDDesignTokens.Geometry.closedEarRadius,
            bottomCornerRadius: isExpanded ? HUDDesignTokens.Geometry.expandedBottomCornerRadius : HUDDesignTokens.Geometry.closedBottomCornerRadius
        )
        .stroke(
            HUDDesignTokens.Gradients.notchBorder(isExpanded: isExpanded),
            lineWidth: isExpanded ? 0.85 : 1.2
        )
    }

    // MARK: - Event Handlers
    private func handleHover(_ hovering: Bool) {
        hoverTask?.cancel()
        if hovering {
            withAnimation(HUDDesignTokens.Springs.fluid) {
                self.isHovering = true
            }
        } else {
            hoverTask = Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                if !Task.isCancelled {
                    await MainActor.run {
                        withAnimation(HUDDesignTokens.Springs.fluid) {
                            self.isHovering = false
                        }
                    }
                }
            }
        }
    }

    private func handleHeightChange(_ newHeight: CGFloat) {
        if newHeight > 0 {
            withAnimation(HUDDesignTokens.Springs.fluid) {
                self.inspectorContentHeight = newHeight
            }
        }
    }

    // MARK: - Top Notch Cap Bar
    private var notchCapBar: some View {
        HStack(spacing: 0) {
            // Left Ear: Locked to left edge with 16pt padding
            HStack(spacing: 7) {
                if !isOrbDownInMessageArea {
                    LivingAuroraOrbView(appState: appState, size: 22, showSquircleBackground: false)
                        .matchedGeometryEffect(id: "auraSingleLivingOrb", in: orbNamespace)
                        .frame(width: 22, height: 22)
                }

                if isHovering || isOrbDownInMessageArea || appState.isTurnCompletedPresented {
                    Text("Aura")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)
                        .fixedSize()
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            .animation(HUDDesignTokens.Springs.fluid, value: isHovering)
            .animation(HUDDesignTokens.Springs.fluid, value: isOrbDownInMessageArea)
            .animation(HUDDesignTokens.Springs.fluid, value: appState.isTurnCompletedPresented)

            // Center Spacer: Exact width & height of the physical MacBook camera notch
            Color.clear
                .frame(width: geometry.notchWidth, height: geometry.notchHeight)

            // Right Ear: Chat Selector in idle, or waveform/orbit when active
            HStack(spacing: 6) {
                rightEarActivityContent
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
        }
        .frame(height: geometry.notchHeight)
    }

    // MARK: - Right Ear Activity Indicators
    @ViewBuilder
    private var rightEarActivityContent: some View {
        switch appState.state {
        case .idle:
            if appState.isTurnCompletedPresented {
                doneButton
            } else {
                chatSelectorView
            }

        case .listening:
            FluidWaveformView(audioLevel: appState.audioLevel)

        case .processing:
            AuroraOrbitSpinner()

        case .speaking:
            SpeakingWaveformView(audioLevel: appState.audioLevel)

        case .awaitingConfirmation:
            HStack(spacing: 4.5) {
                Circle()
                    .fill(HUDDesignTokens.Colors.actionAmber)
                    .frame(width: 5, height: 5)
                    .shadow(color: HUDDesignTokens.Colors.actionAmber.opacity(0.6), radius: 2)
                Text("Action")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(HUDDesignTokens.Colors.actionAmber)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(HUDDesignTokens.Colors.actionAmber.opacity(0.16)))
            .overlay(Capsule().stroke(HUDDesignTokens.Colors.actionAmber.opacity(0.35), lineWidth: 0.5))

        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(HUDDesignTokens.Colors.errorRed)
                .font(.system(size: 12))
        }
    }

    // MARK: - Chat Selector (Right Ear in Idle)
    private var chatSelectorView: some View {
        Menu {
            Button {
                withAnimation(HUDDesignTokens.Springs.snappy) {
                    sessionManager.selectNewChat()
                }
            } label: {
                if sessionManager.selectedSessionId == nil {
                    Label("New Chat", systemImage: "checkmark")
                } else {
                    Label("New Chat", systemImage: "plus.bubble")
                }
            }

            Divider()

            if !sessionManager.sessions.isEmpty {
                Section("Saved Chats") {
                    ForEach(sessionManager.sessions.prefix(8)) { session in
                        Button {
                            withAnimation(HUDDesignTokens.Springs.snappy) {
                                sessionManager.selectSession(id: session.id)
                            }
                        } label: {
                            if sessionManager.selectedSessionId == session.id {
                                Label(session.title, systemImage: "checkmark")
                            } else {
                                Text(session.title)
                            }
                        }
                    }
                }
            }

            Divider()

            Button {
                SettingsWindowController.shared.showChat()
            } label: {
                Label("Open in Full App", systemImage: "arrow.up.forward.app")
            }
        } label: {
            HStack(spacing: 5) {
                if let selected = currentSelectedSession {
                    Circle()
                        .fill(Color(red: 0.25, green: 0.65, blue: 1.0))
                        .frame(width: 5, height: 5)

                    Text("\(selected.messages.count) msgs")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                } else {
                    Image(systemName: "sparkle")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Color(red: 0.75, green: 0.55, blue: 1.0))

                    Text("Fresh")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.88))
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(
                Capsule()
                    .fill(Color.white.opacity(isHovering ? 0.12 : 0.06))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isHovering ? 0.18 : 0.08), lineWidth: 0.5)
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - Done Button (Shown on Right Ear Post-Speech)
    private var doneButton: some View {
        Button {
            withAnimation(HUDDesignTokens.Springs.fluid) {
                appState.dismissTurnCompleted()
            }
        } label: {
            HStack(spacing: 4.5) {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(HUDDesignTokens.Colors.emeraldSuccess)

                Text("Done")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                MiniKeycapView("⎋")
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.18))
            )
            .overlay(
                Capsule()
                    .stroke(Color.green.opacity(0.40), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help("Dismiss result (or press Esc)")
        .fixedSize()
    }

    // MARK: - Expanded Dropdown Content
    @ViewBuilder
    private var expandedContent: some View {
        if (isHovering || appState.isTurnCompletedPresented) && appState.state == .idle {
            LastTurnInspectorView(
                session: currentSelectedSession,
                sessionManager: sessionManager,
                onDismissHover: {
                    self.isHovering = false
                }
            )
        } else {
            ActiveTurnLiveView(
                appState: appState,
                orbNamespace: orbNamespace,
                isOrbDownInMessageArea: isOrbDownInMessageArea
            )
        }
    }
}
