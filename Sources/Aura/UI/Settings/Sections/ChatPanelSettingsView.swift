import SwiftUI

/// Full-featured ChatGPT-style interactive Chat Hub for Aura.
/// Features thread persistence, auto-titling, dual typing/voice input, and collapsible tool inspection cards.
public struct ChatPanelSettingsView: View {
    @ObservedObject public var sessionManager = AgentSessionManager.shared
    @ObservedObject public var appState: AppState

    @State private var inputText: String = ""
    @State private var isRecordingVoice: Bool = false
    @State private var editingSessionId: String? = nil
    @State private var renameText: String = ""

    public init(appState: AppState = .shared) {
        self.appState = appState
    }

    public var body: some View {
        HSplitView {
            // MARK: - Left Thread List Sidebar
            threadListSidebar
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)

            // MARK: - Right Conversation Area
            conversationMainArea
                .frame(minWidth: 460)
        }
    }

    // MARK: - Subviews: Thread List
    private var threadListSidebar: some View {
        VStack(spacing: 0) {
            // New Chat Button
            Button {
                withAnimation {
                    _ = sessionManager.createNewSession()
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("New Chat")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.12))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(12)

            Divider()

            // Session List
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(sessionManager.sessions) { session in
                        threadRow(session: session)
                    }
                }
                .padding(8)
            }
        }
        .background {
            Color(nsColor: .controlBackgroundColor).opacity(0.5)
        }
    }

    private func threadRow(session: ConversationSession) -> some View {
        let isSelected = session.id == sessionManager.activeSession.id

        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                if editingSessionId == session.id {
                    TextField("Title", text: $renameText, onCommit: {
                        sessionManager.renameSession(id: session.id, newTitle: renameText)
                        editingSessionId = nil
                    })
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                } else {
                    Text(session.title)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                }

                Text(formattedDate(session.updatedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }

            Spacer()

            // Thread Actions Menu
            Menu {
                Button("Rename") {
                    renameText = session.title
                    editingSessionId = session.id
                }
                Button(role: .destructive) {
                    withAnimation {
                        sessionManager.deleteSession(id: session.id)
                    }
                } label: {
                    Text("Delete")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 18)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? Color.primary.opacity(0.08) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                sessionManager.selectSession(id: session.id)
            }
        }
    }

    // MARK: - Subviews: Conversation Area
    private var conversationMainArea: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionManager.activeSession.title)
                        .font(.headline)
                    Text("\(sessionManager.activeSession.messages.count) messages")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Message Stream
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if sessionManager.activeSession.messages.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(sessionManager.activeSession.messages) { message in
                                messageBubble(message: message)
                                    .id(message.id)
                            }
                        }

                        if sessionManager.isProcessing {
                            processingIndicator
                                .id("processing_indicator")
                        }
                    }
                    .padding(20)
                }
                .onChange(of: sessionManager.activeSession.messages.count) { _, _ in
                    if let lastId = sessionManager.activeSession.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input Bar
            inputBar
        }
    }

    // MARK: - Message Bubble
    private func messageBubble(message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Header (Role & Input Mode)
                HStack(spacing: 6) {
                    if message.role == .user {
                        if message.isVoice {
                            Image(systemName: "mic.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        Text("You")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Text("Aura")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.purple)
                    }
                }

                // Tool Calls (Expandable Cards)
                if !message.toolCalls.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(message.toolCalls) { toolCall in
                            ToolCallCardView(toolCall: toolCall)
                        }
                    }
                }

                // Message Text Content
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            message.role == .user
                                ? Color.blue.opacity(0.18)
                                : Color(NSColor.controlBackgroundColor)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                }
            }

            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // Live Microphone Dictation Button
            Button {
                toggleChatMic()
            } label: {
                ZStack {
                    Circle()
                        .fill(isRecordingVoice ? Color.red : Color.primary.opacity(0.08))
                        .frame(width: 34, height: 34)

                    Image(systemName: isRecordingVoice ? "stop.fill" : "mic.fill")
                        .font(.subheadline)
                        .foregroundColor(isRecordingVoice ? .white : .primary)
                }
            }
            .buttonStyle(.plain)
            .help(isRecordingVoice ? "Stop speaking and send" : "Talk to Aura (Voice)")

            // Text Input
            TextField("Ask Aura anything...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .onSubmit {
                    sendTextMessage()
                }

            // Send Button
            Button {
                sendTextMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary.opacity(0.4) : .blue)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sessionManager.isProcessing)
            .help("Send Message (Silent response)")
        }
        .padding(14)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 38))
                .foregroundColor(.blue.opacity(0.7))
            Text("Start a conversation with Aura")
                .font(.headline)
            Text("Type a message below or speak naturally. Aura executes native tools, inspects your files, and maintains context across turns.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    private var processingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.7)
            Text(currentProcessingText)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var currentProcessingText: String {
        if case .processing(let phase) = appState.state {
            return phase
        }
        return "Thinking..."
    }

    // MARK: - Actions
    private func sendTextMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !sessionManager.isProcessing else { return }

        inputText = ""
        Task {
            await sessionManager.processPrompt(text: text, isVoice: false)
        }
    }

    private func toggleChatMic() {
        if isRecordingVoice {
            // Stop recording and submit voice turn
            isRecordingVoice = false
            AudioCaptureService.shared.stopCapture()
            NativeSpeechRecognizer.shared.stopRecognition()

            let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            inputText = ""
            guard !text.isEmpty else { return }

            Task {
                await sessionManager.processPrompt(text: text, isVoice: true)
            }
        } else {
            // Start recording
            isRecordingVoice = true
            inputText = ""
            do {
                try NativeSpeechRecognizer.shared.startRecognition { liveText, isFinal in
                    Task { @MainActor in
                        self.inputText = liveText
                    }
                }
                try AudioCaptureService.shared.startCapture { buffer in
                    NativeSpeechRecognizer.shared.appendAudioBuffer(buffer)
                }
            } catch {
                isRecordingVoice = false
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// Expandable card representing an autonomous tool call.
public struct ToolCallCardView: View {
    @State public var toolCall: ToolCallRecord
    @State private var isExpanded: Bool = false

    public init(toolCall: ToolCallRecord) {
        self._toolCall = State(initialValue: toolCall)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                        .frame(width: 10)

                    Image(systemName: iconForTool(toolCall.toolName))
                        .foregroundColor(.purple)
                        .font(.caption)

                    Text(toolCall.toolName)
                        .font(.caption.weight(.semibold).monospaced())
                        .foregroundColor(.primary)

                    if toolCall.latencyMs > 0 {
                        Text("\(toolCall.latencyMs)ms")
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Status Pill
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(statusText)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(statusColor)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .buttonStyle(.plain)

            // Collapsible Details
            if isExpanded {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    if !toolCall.argumentsJson.isEmpty && toolCall.argumentsJson != "{}" {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("INPUT ARGUMENTS")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(toolCall.argumentsJson)
                                .font(.caption.monospaced())
                                .padding(6)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(4)
                        }
                    }

                    if !toolCall.output.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("TOOL OUTPUT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(toolCall.output)
                                .font(.caption.monospaced())
                                .padding(6)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(10)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch toolCall.status {
        case .running: return .blue
        case .success: return .green
        case .failure: return .red
        }
    }

    private var statusText: String {
        switch toolCall.status {
        case .running: return "Running"
        case .success: return "Success"
        case .failure: return "Failed"
        }
    }

    private func iconForTool(_ name: String) -> String {
        switch name {
        case "open_application": return "app.badge.fill"
        case "adjust_volume": return "speaker.wave.2.fill"
        case "take_screenshot": return "camera.fill"
        case "list_files": return "folder.fill"
        case "execute_terminal_command": return "terminal.fill"
        case "search_emails": return "envelope.fill"
        case "query_notion": return "doc.text.fill"
        default: return "gearshape.fill"
        }
    }
}
