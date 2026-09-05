import SwiftUI

/// Inspector card revealed when hovering the notch in idle mode or inspecting the completed turn.
public struct LastTurnInspectorView: View {
    public let session: ConversationSession?
    @ObservedObject public var sessionManager: AgentSessionManager
    public var onDismissHover: () -> Void

    public init(
        session: ConversationSession?,
        sessionManager: AgentSessionManager = .shared,
        onDismissHover: @escaping () -> Void = {}
    ) {
        self.session = session
        self.sessionManager = sessionManager
        self.onDismissHover = onDismissHover
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Bar
            headerBar

            // Body
            if let session, !session.messages.isEmpty {
                sessionMessagesBody(session: session)
            } else {
                freshChatReadyBody
            }
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 8) {
            if let session {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)

                    Text(session.title)
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                )
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.75, green: 0.55, blue: 1.0))

                    Text("New Chat Mode")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Color.purple.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.purple.opacity(0.25), lineWidth: 0.5)
                )
            }

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                // New Chat Button
                Button {
                    withAnimation(HUDDesignTokens.Springs.snappy) {
                        sessionManager.selectNewChat()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 8, weight: .bold))
                        Text("New Chat")
                    }
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundColor(sessionManager.selectedSessionId == nil ? Color(red: 0.80, green: 0.60, blue: 1.0) : .white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(sessionManager.selectedSessionId == nil ? Color.purple.opacity(0.25) : Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(sessionManager.selectedSessionId == nil ? Color.purple.opacity(0.40) : Color.white.opacity(0.10), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .help("Start a fresh conversation")

                // Open in Full App Button
                Button {
                    SettingsWindowController.shared.showChat()
                    withAnimation(HUDDesignTokens.Springs.snappy) {
                        onDismissHover()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Open in Full App")
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 8))
                    }
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color.blue.opacity(0.14))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.blue.opacity(0.28), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .help("Open full chat thread in Aura Control Center")
            }
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 2)
    }

    // MARK: - Session Messages Body
    private func sessionMessagesBody(session: ConversationSession) -> some View {
        let lastUserMsg = session.messages.last(where: { $0.role == .user })
        let lastAssistantMsg = session.messages.last(where: { $0.role == .assistant })

        return VStack(alignment: .leading, spacing: 8) {
            // User Prompt Card
            if let userMsg = lastUserMsg {
                HUDGlassCard {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4.5) {
                            if userMsg.isVoice {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                            }
                            Text("You")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.blue.opacity(0.85))
                        }

                        Text(userMsg.content)
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Executed Tool Cards
            if let assistantMsg = lastAssistantMsg, !assistantMsg.toolCalls.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(HUDDesignTokens.Colors.processingOrchid)
                        Text("EXECUTED TOOLS")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(HUDDesignTokens.Colors.processingOrchid)
                    }
                    .padding(.leading, 2)

                    ForEach(assistantMsg.toolCalls) { toolCall in
                        ToolCallCardView(toolCall: toolCall)
                            .clipShape(RoundedRectangle(cornerRadius: HUDDesignTokens.Geometry.toolCardCornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: HUDDesignTokens.Geometry.toolCardCornerRadius, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                            )
                    }
                }
            }

            // Assistant Response Card
            if let assistantMsg = lastAssistantMsg, !assistantMsg.content.isEmpty {
                HUDGlassCard {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            HStack(spacing: 4.5) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8))
                                    .foregroundColor(HUDDesignTokens.Colors.processingOrchid)
                                Text("Aura")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(HUDDesignTokens.Colors.processingOrchid)
                            }

                            Spacer()

                            HUDCopyButton(text: assistantMsg.content)
                        }

                        Text(assistantMsg.content)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.92))
                            .lineSpacing(3)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.trailing, 2)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geo.size.height)
            }
        )
    }

    // MARK: - Fresh Chat Ready Body
    private var freshChatReadyBody: some View {
        HUDGlassCard {
            VStack(alignment: .center, spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.75, green: 0.55, blue: 1.0))

                Text("Ready for a fresh conversation")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text("Your next message will start a new chat with clean memory.")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 14)
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geo.size.height)
            }
        )
    }
}
