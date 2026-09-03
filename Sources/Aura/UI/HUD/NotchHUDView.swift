import SwiftUI

/// Main HUD overlay view that spans the MacBook notch and drops down dynamically.
public struct NotchHUDView: View {
    @ObservedObject public var appState: AppState
    @ObservedObject public var geometry: NotchGeometry
    @ObservedObject public var sessionManager = AgentSessionManager.shared

    @State private var isHovering: Bool = false
    @State private var hoverTask: Task<Void, Never>? = nil
    @State private var inspectorContentHeight: CGFloat = 0
    @Namespace private var orbNamespace

    public init(appState: AppState = .shared, geometry: NotchGeometry) {
        self.appState = appState
        self.geometry = geometry
    }

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
            return max(geometry.closedWidth, 500)
        }
        return geometry.closedWidth
    }

    private var targetHeight: CGFloat {
        if isExpanded {
            if (isHovering || appState.isTurnCompletedPresented) && appState.state == .idle {
                if inspectorContentHeight > 0 {
                    return min(800, geometry.notchHeight + inspectorContentHeight + 56)
                }
                let session = currentSelectedSession
                let hasTools = session?.messages.last?.toolCalls.isEmpty == false
                return hasTools ? geometry.notchHeight + 220 : geometry.notchHeight + 140
            }

            switch appState.state {
            case .listening:
                let textLength = appState.partialTranscript.count
                if textLength > 100 {
                    return geometry.notchHeight + 120
                }
                return geometry.notchHeight + 92

            case .processing:
                return geometry.notchHeight + 92

            case .speaking(let text):
                // Dynamically expand for longer responses so lines fit gracefully
                let count = text.count
                let lineBreaks = text.components(separatedBy: "\n").count
                if count > 280 || lineBreaks >= 6 {
                    return min(320, geometry.notchHeight + 205)
                } else if count > 150 || lineBreaks >= 4 {
                    return geometry.notchHeight + 155
                } else if count > 65 || lineBreaks >= 2 {
                    return geometry.notchHeight + 120
                } else {
                    return geometry.notchHeight + 92
                }

            case .awaitingConfirmation:
                return geometry.notchHeight + 120

            case .error:
                return geometry.notchHeight + 85

            default:
                return geometry.notchHeight + 92
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

    public var body: some View {
        VStack(spacing: 0) {
            // Top Notch Cap Bar (Left Ear | Center Spacer | Right Ear)
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
        .background(
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.05).opacity(0.96)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.35)
            }
        )
        .clipShape(NotchShape(topEarRadius: 6, bottomCornerRadius: isExpanded ? 20 : 14))
        .overlay(
            NotchBorderShape(topEarRadius: 6, bottomCornerRadius: isExpanded ? 20 : 14)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isExpanded ? 0.20 : 0.08),
                            Color.white.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
        )
        .shadow(color: Color.black.opacity(isExpanded ? 0.45 : 0.0), radius: isExpanded ? 20 : 0, y: isExpanded ? 8 : 0)
        .contentShape(Rectangle())
        .onHover { hovering in
            hoverTask?.cancel()
            if hovering {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    self.isHovering = true
                }
            } else {
                hoverTask = Task {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    if !Task.isCancelled {
                        await MainActor.run {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                self.isHovering = false
                            }
                        }
                    }
                }
            }
        }
        .onPreferenceChange(ContentHeightPreferenceKey.self) { newHeight in
            if newHeight > 0 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    self.inspectorContentHeight = newHeight
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: targetHeight)
    }

    // MARK: - Top Notch Cap Bar
    private var notchCapBar: some View {
        HStack(spacing: 0) {
            // Left Ear: Locked to left edge with 12pt padding
            HStack(spacing: 7) {
                if !isOrbDownInMessageArea {
                    LivingAuroraOrbView(appState: appState, size: 22, showSquircleBackground: false)
                        .matchedGeometryEffect(id: "auraSingleLivingOrb", in: orbNamespace)
                        .frame(width: 22, height: 22)
                }

                if isHovering || isOrbDownInMessageArea || appState.isTurnCompletedPresented {
                    Text("Aura")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)
                        .fixedSize()
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: isHovering)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: isOrbDownInMessageArea)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: appState.isTurnCompletedPresented)

            // Center Spacer: Exact width & height of the physical MacBook camera notch
            Color.clear
                .frame(width: geometry.notchWidth, height: geometry.notchHeight)

            // Right Ear: Chat Selector in idle, or waveform/loader when active
            HStack(spacing: 6) {
                rightEarActivityContent
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
        }
        .frame(height: geometry.notchHeight)
    }

    @AppStorage("enableAmbientGlow") private var enableAmbientGlow: Bool = true

    private var stateColor: Color {
        switch appState.state {
        case .idle:
            return Color.gray.opacity(0.7)
        case .listening:
            return Color.red
        case .processing:
            return Color.cyan
        case .speaking:
            return Color(red: 0.2, green: 0.85, blue: 0.4)
        case .awaitingConfirmation:
            return Color.orange
        case .error:
            return Color.red
        }
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
            // Fluid waveform dancing with user voice
            FluidWaveformView(audioLevel: appState.audioLevel)

        case .processing:
            // Processing loader
            HStack(spacing: 5) {
                ProgressView()
                    .scaleEffect(0.65)
                    .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                Text("Running")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
            }

        case .speaking:
            // Speaking equalizer waveform
            SpeakingWaveformView()

        case .awaitingConfirmation:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 5, height: 5)
                Text("Action")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(Color.orange.opacity(0.18))
            .cornerRadius(5)

        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
                .font(.system(size: 12))
        }
    }

    // MARK: - Chat Selector (Right Ear in Idle)
    private var chatSelectorView: some View {
        Menu {
            // Option 1: New Chat (Unselected state)
            Button {
                withAnimation {
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

            // Option 2: Existing saved conversations
            if !sessionManager.sessions.isEmpty {
                Section("Saved Chats") {
                    ForEach(sessionManager.sessions.prefix(8)) { session in
                        Button {
                            withAnimation {
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

            // Option 3: Open in Control Center
            Button {
                SettingsWindowController.shared.showChat()
            } label: {
                Label("Open in Control Center", systemImage: "arrow.up.forward.app")
            }
        } label: {
            HStack(spacing: 4) {
                if let selected = currentSelectedSession {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)

                    Text("\(selected.messages.count) msgs")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                } else {
                    Image(systemName: "sparkle")
                        .font(.system(size: 8))
                        .foregroundColor(.purple)

                    Text("Fresh")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(Color.white.opacity(0.12))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - Done Button (Shown on Right Ear Post-Speech)
    private var doneButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                appState.dismissTurnCompleted()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green)

                Text("Done")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(Color.green.opacity(0.18))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green.opacity(0.35), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help("Dismiss result (or press Esc)")
        .fixedSize()
    }

    private func truncatedTitle(_ title: String) -> String {
        if title.count > 12 {
            return String(title.prefix(11)) + "…"
        }
        return title
    }

    // MARK: - Expanded Dropdown Content
    @ViewBuilder
    private var expandedContent: some View {
        if (isHovering || appState.isTurnCompletedPresented) && appState.state == .idle {
            lastTurnInspectorContent
        } else {
            activeTurnLiveContent
        }
    }

    // MARK: - Last Turn Inspector (Hover State)
    private var lastTurnInspectorContent: some View {
        let session = currentSelectedSession

        return VStack(alignment: .leading, spacing: 8) {
            // Header Bar
            HStack(spacing: 8) {
                if let session {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)

                        Text(session.title)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(.purple)

                        Text("New Chat Mode")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                Spacer(minLength: 12)

                HStack(spacing: 6) {
                    Button {
                        withAnimation {
                            sessionManager.selectNewChat()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 8, weight: .bold))
                            Text("New Chat")
                        }
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(sessionManager.selectedSessionId == nil ? .purple : .white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(sessionManager.selectedSessionId == nil ? Color.purple.opacity(0.25) : Color.white.opacity(0.12))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    .help("Start a fresh conversation")

                    Button {
                        SettingsWindowController.shared.showChat()
                        withAnimation {
                            isHovering = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Open in Full App")
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 8))
                        }
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    .help("Open full chat thread in Aura Control Center")
                }
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 2)

            Divider()
                .background(Color.white.opacity(0.15))

            // Body
            if let session, !session.messages.isEmpty {
                let lastUserMsg = session.messages.last(where: { $0.role == .user })
                let lastAssistantMsg = session.messages.last(where: { $0.role == .assistant })
                VStack(alignment: .leading, spacing: 10) {
                    if let userMsg = lastUserMsg {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                if userMsg.isVoice {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.blue)
                                }
                                Text("YOU")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Text(userMsg.content)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Full Tool Call UI in Notch
                    if let assistantMsg = lastAssistantMsg, !assistantMsg.toolCalls.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TOOLS EXECUTED")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.purple.opacity(0.8))

                            ForEach(assistantMsg.toolCalls) { toolCall in
                                ToolCallCardView(toolCall: toolCall)
                            }
                        }
                    }

                    if let assistantMsg = lastAssistantMsg, !assistantMsg.content.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8))
                                    .foregroundColor(.purple)
                                Text("AURA")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.purple.opacity(0.8))
                            }
                            Text(assistantMsg.content)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.trailing, 2)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geo.size.height)
                    }
                )
            } else {
                // Clean new chat ready state
                VStack(alignment: .center, spacing: 6) {
                    Text("Ready for a fresh conversation")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    Text("Your next message will start a new chat with clean memory.")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 14)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geo.size.height)
                    }
                )
            }
        }
    }

    // MARK: - Active Turn Live Content (Listening / Processing / Speaking)
    @ViewBuilder
    private var activeTurnLiveContent: some View {
        HStack(alignment: .top, spacing: 14) {
            if isOrbDownInMessageArea {
                LivingAuroraOrbView(appState: appState, size: 40, showSquircleBackground: false)
                    .matchedGeometryEffect(id: "auraSingleLivingOrb", in: orbNamespace)
                    .frame(width: 40, height: 40)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 6) {
                // 1. Consistent Message Content Box (Fixed Height: 54pt)
                Group {
                    switch appState.state {
                    case .listening:
                        ScrollView(.vertical, showsIndicators: false) {
                            Text(appState.partialTranscript.isEmpty ? "Listening..." : appState.partialTranscript)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                                .animation(.easeInOut(duration: 0.15), value: appState.partialTranscript)
                        }

                    case .processing(let phase):
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phase)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                                .lineLimit(2)
                            Text("Aura is working on your request...")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }

                    case .speaking(let text):
                        ScrollView(.vertical, showsIndicators: false) {
                            Text(text)
                                .font(.system(size: 12.5, weight: .regular))
                                .foregroundColor(.white.opacity(0.95))
                                .lineSpacing(2.5)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                    case .awaitingConfirmation(let request):
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 12))
                                Text(request.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }

                            Text(request.description)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)

                            Text(request.commandOrAction)
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(4)
                                .background(Color.black.opacity(0.35))
                                .cornerRadius(4)
                                .lineLimit(2)
                        }

                    case .error(let message):
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(message)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }

                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // 2. Consistent Footer Row (Pinned to the very bottom of the notch)
                HStack(alignment: .center) {
                    // Left Status / Hint
                    Group {
                        switch appState.state {
                        case .listening:
                            HStack(spacing: 4) {
                                Text("Press")
                                    .foregroundColor(.white.opacity(0.45))
                                Text(appState.hotkeyDisplayString)
                                    .foregroundColor(.white.opacity(0.85))
                                    .fontWeight(.semibold)
                                Text("again to send")
                                    .foregroundColor(.white.opacity(0.45))
                            }
                            .font(.system(size: 10, design: .rounded))

                        case .processing:
                            HStack(spacing: 5) {
                                ProgressView()
                                    .scaleEffect(0.55)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                Text("Thinking...")
                                    .foregroundColor(.white.opacity(0.45))
                            }
                            .font(.system(size: 10, design: .rounded))

                        case .speaking:
                            HStack(spacing: 4) {
                                Text("Speaking...")
                                    .foregroundColor(.white.opacity(0.45))
                            }
                            .font(.system(size: 10, design: .rounded))

                        case .awaitingConfirmation(let request):
                            HStack(spacing: 8) {
                                Button {
                                    ApprovalCoordinator.shared.approve(id: request.id)
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "checkmark")
                                        Text("Approve")
                                    }
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.8))
                                    .cornerRadius(5)
                                }

                                Button {
                                    ApprovalCoordinator.shared.deny(id: request.id)
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "xmark")
                                        Text("Deny")
                                    }
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(5)
                                }
                            }
                            .buttonStyle(.plain)

                        default:
                            EmptyView()
                        }
                    }

                    Spacer()

                    // Right Action: ALWAYS Open Chat at the exact same location!
                    Button {
                        SettingsWindowController.shared.showChat()
                        withAnimation {
                            appState.resetToIdle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 8))
                            Text("Open Chat")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                    .help("Open full chat thread in Aura Control Center")
                }
                .frame(height: 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxHeight: .infinity)
    }
}

/// Real-time audio waveform view that pulses with microphone input level.
public struct FluidWaveformView: View {
    public let audioLevel: Float

    public init(audioLevel: Float) {
        self.audioLevel = audioLevel
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.red)
                    .frame(
                        width: 2.5,
                        height: max(4, CGFloat(audioLevel) * 20 * CGFloat([0.5, 0.9, 1.2, 0.8, 0.4][index]))
                    )
                    .animation(.spring(response: 0.15, dampingFraction: 0.6), value: audioLevel)
            }
        }
        .frame(height: 14)
    }
}

/// Equalizer waveform view animated during speech synthesis.
public struct SpeakingWaveformView: View {
    @State private var animating: Bool = false

    public init() {}

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color(red: 0.2, green: 0.85, blue: 0.4))
                    .frame(width: 2.5, height: animating ? CGFloat([8, 14, 11, 15, 7][index]) : 4)
                    .animation(
                        Animation.easeInOut(duration: 0.35)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.08),
                        value: animating
                    )
            }
        }
        .frame(height: 16)
        .onAppear {
            animating = true
        }
    }
}

/// Measures dynamic content height of the notch inspector for auto-expanding height
public struct ContentHeightPreferenceKey: PreferenceKey {
    public static let defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 {
            value = next
        }
    }
}
