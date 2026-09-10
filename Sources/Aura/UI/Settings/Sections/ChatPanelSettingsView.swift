import AppKit
import SwiftUI
import OpenAgentSDK

/// In-memory preview item for images attached via clipboard paste
public struct AttachedImageItem: Identifiable, Equatable {
    public let id: String
    public let filePath: String
    public let thumbnail: NSImage
    public let data: Data
    public let mimeType: String

    public init(id: String = UUID().uuidString, filePath: String, thumbnail: NSImage, data: Data, mimeType: String) {
        self.id = id
        self.filePath = filePath
        self.thumbnail = thumbnail
        self.data = data
        self.mimeType = mimeType
    }

    public static func == (lhs: AttachedImageItem, rhs: AttachedImageItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Full-featured ChatGPT-style interactive Chat Hub for Aura.
/// Features thread persistence, auto-titling, dual typing/voice input, collapsible thread drawer,
/// and collapsible tool inspection cards, styled with the obsidian liquid-glass design system.
public struct ChatPanelSettingsView: View {
    @ObservedObject public var sessionManager = AgentSessionManager.shared
    @ObservedObject public var appState: AppState
    @Binding public var isThreadListVisible: Bool

    @State private var inputText: String = ""
    @State private var attachedImages: [AttachedImageItem] = []
    @State private var isRecordingVoice: Bool = false
    @State private var editingSessionId: String? = nil
    @State private var renameText: String = ""

    public init(appState: AppState = .shared, isThreadListVisible: Binding<Bool> = .constant(true)) {
        self.appState = appState
        self._isThreadListVisible = isThreadListVisible
    }

    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Thread List Pane (Collapsible drawer sliding under main sidebar)
            if isThreadListVisible {
                HStack(spacing: 0) {
                    threadListSidebar
                        .frame(width: 220)

                    // Specular Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1)
                }
                .transition(.move(edge: .leading))
                .zIndex(1)
            }

            // MARK: - Right Conversation Area
            conversationMainArea
                .frame(minWidth: 460)
                .zIndex(2)
        }
    }

    // MARK: - Subviews: Thread List
    private var threadListSidebar: some View {
        VStack(spacing: 0) {
            // New Chat Button
            Button {
                withAnimation(ControlCenterTokens.Motion.snappy) {
                    _ = sessionManager.createNewSession()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("New Thread")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [
                            ControlCenterTokens.Colors.accentIndigo.opacity(0.35),
                            ControlCenterTokens.Colors.accentIndigo.opacity(0.15)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(ControlCenterTokens.Radii.button)
                .overlay(
                    RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.button)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(12)

            Divider()
                .overlay(Color.white.opacity(0.06))

            // Session List
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(sessionManager.sessions) { session in
                        threadRow(session: session)
                    }
                }
                .padding(8)
            }
        }
        .background(ControlCenterTokens.Colors.sidebarBackdrop.opacity(0.6))
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
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
                } else {
                    Text(session.title)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                        .lineLimit(1)
                }

                Text(formattedDate(session.updatedAt))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
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
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .frame(width: 18)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(ControlCenterTokens.Motion.snappy) {
                sessionManager.selectSession(id: session.id)
            }
        }
    }

    // MARK: - Subviews: Conversation Area
    private var conversationMainArea: some View {
        VStack(spacing: 0) {
            // Message Stream (seamlessly connected under the unified Antigravity header)
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

                        if case .awaitingConfirmation(let request) = appState.state {
                            confirmationBanner(request: request)
                                .id("confirmation_banner")
                        } else if sessionManager.isProcessing {
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
                .onChange(of: appState.state) { _, newState in
                    if case .awaitingConfirmation = newState {
                        withAnimation {
                            proxy.scrollTo("confirmation_banner", anchor: .bottom)
                        }
                    }
                }
            }

            // Floating Input Dock
            inputBar
        }
        .background(ControlCenterTokens.Colors.windowBackdrop)
    }

    // MARK: - Message Bubble
    private func messageBubble(message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                // Header (Role & Mode)
                HStack(spacing: 6) {
                    if message.role == .user {
                        if message.isVoice {
                            HStack(spacing: 3) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 9))
                                Text("Voice")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(ControlCenterTokens.Colors.accentIndigo.opacity(0.3))
                            .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                            .cornerRadius(3)
                        }
                        Text("You")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    } else {
                        LivingAuroraOrbView(appState: appState, size: 14, showSquircleBackground: false)
                        Text("Aura")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(ControlCenterTokens.Colors.accentPurple)
                    }
                }

                // Attached Images
                if let imagePaths = message.imagePaths, !imagePaths.isEmpty {
                    VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                        ForEach(imagePaths, id: \.self) { path in
                            ToolCallImagePreviewView(imagePath: path)
                        }
                    }
                }

                // Tool Calls
                if !message.toolCalls.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(message.toolCalls) { toolCall in
                            ToolCallCardView(toolCall: toolCall)
                        }
                    }
                }

                // Text Content
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.92))
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background {
                            if message.role == .user {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(ControlCenterTokens.Gradients.userBubble)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.glassSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(ControlCenterTokens.Gradients.specularBorder, lineWidth: 1)
                                    )
                            }
                        }
                        .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                }
            }

            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }

    // MARK: - Input Bar Dock
    private var inputBar: some View {
        VStack(spacing: 0) {
            if !attachedImages.isEmpty {
                attachedImagesBar
                Divider()
                    .overlay(Color.white.opacity(0.06))
            }

            HStack(alignment: .bottom, spacing: 10) {
                microphoneButton
                textInputField
                sendButton
            }
            .padding(14)
        }
        .background(ControlCenterTokens.Colors.sidebarBackdrop)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1),
            alignment: .top
        )
    }

    private var microphoneButton: some View {
        Button {
            toggleChatMic()
        } label: {
            ZStack {
                Circle()
                    .fill(isRecordingVoice ? Color.red : Color.white.opacity(0.08))
                    .frame(width: 34, height: 34)

                if isRecordingVoice {
                    Circle()
                        .stroke(Color.red.opacity(0.4), lineWidth: 4)
                        .frame(width: 42, height: 42)
                }

                Image(systemName: isRecordingVoice ? "stop.fill" : "mic.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isRecordingVoice ? .white : .white.opacity(0.85))
            }
        }
        .buttonStyle(.plain)
        .help(isRecordingVoice ? "Stop speaking and send" : "Talk to Aura (Voice)")
    }

    private var textInputField: some View {
        ZStack(alignment: .leading) {
            if inputText.isEmpty {
                Text("Ask Aura anything... (Return to send, Shift+Return for newline)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }

            TextField("", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .lineLimit(1...6)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .onKeyPress { keyPress in
                    if keyPress.key == .return {
                        if keyPress.modifiers.contains(.shift) || keyPress.modifiers.contains(.option) {
                            inputText.append("\n")
                            return .handled
                        } else {
                            sendTextMessage()
                            return .handled
                        }
                    }
                    if keyPress.key == KeyEquivalent("v") && keyPress.modifiers.contains(.command) {
                        if handlePasteImageFromClipboard() {
                            return .handled
                        }
                    }
                    return .ignored
                }
        }
        .background(ControlCenterTokens.Colors.sunkenSurface)
        .cornerRadius(ControlCenterTokens.Radii.innerCard)
        .overlay(
            RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.innerCard)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var sendButton: some View {
        let canSend = (!inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachedImages.isEmpty) && !sessionManager.isProcessing

        return Button {
            sendTextMessage()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(
                    canSend
                        ? ControlCenterTokens.Colors.accentIndigo
                        : Color.white.opacity(0.18)
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .help("Send Message (Return)")
    }

    // MARK: - Attached Images Chips Bar
    private var attachedImagesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachedImages) { item in
                    ZStack(alignment: .topTrailing) {
                        HStack(spacing: 8) {
                            Image(nsImage: item.thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(URL(fileURLWithPath: item.filePath).lastPathComponent)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)
                                    .frame(maxWidth: 120, alignment: .leading)

                                Text("\(formattedByteCount(item.data.count)) • \(item.mimeType.replacingOccurrences(of: "image/", with: "").uppercased())")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.45))
                            }
                            .padding(.trailing, 16)
                        }
                        .padding(6)
                        .background(ControlCenterTokens.Colors.sunkenSurface)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )

                        // Discard Button
                        Button {
                            withAnimation(ControlCenterTokens.Motion.snappy) {
                                attachedImages.removeAll(where: { $0.id == item.id })
                                try? FileManager.default.removeItem(atPath: item.filePath)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .background(Circle().fill(Color.black.opacity(0.7)))
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                        .help("Remove image")
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            LivingAuroraOrbView(appState: appState, size: 54, showSquircleBackground: false)
                .shadow(color: ControlCenterTokens.Colors.accentIndigo.opacity(0.4), radius: 16)

            VStack(spacing: 4) {
                Text("What can Aura do for you?")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Speak naturally, type instructions, or trigger autonomous tasks.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
            }

            // Quick Prompt Suggestions
            HStack(spacing: 8) {
                suggestionChip("Summarize current window")
                suggestionChip("Inspect clipboard & files")
                suggestionChip("System diagnostics")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            inputText = text
        } label: {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var processingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.mini)
                .scaleEffect(0.75)
            Text(currentProcessingText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ControlCenterTokens.Colors.glassSurface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var currentProcessingText: String {
        if case .processing(let phase) = appState.state {
            return phase
        }
        return "Thinking..."
    }

    private func confirmationBanner(request: ActionConfirmationRequest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(ControlCenterTokens.Colors.accentAmber)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text(request.description)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }

            Text(request.commandOrAction)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(ControlCenterTokens.Colors.accentAmber)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ControlCenterTokens.Colors.sunkenSurface)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(ControlCenterTokens.Colors.accentAmber.opacity(0.3), lineWidth: 1)
                )

            HStack(spacing: 10) {
                Spacer()
                Button {
                    ApprovalCoordinator.shared.deny(id: request.id)
                } label: {
                    Text("Deny")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button {
                    ApprovalCoordinator.shared.approve(id: request.id)
                } label: {
                    Text("Approve")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(ControlCenterTokens.Colors.accentEmerald)
                        .foregroundColor(.black)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(ControlCenterTokens.Colors.accentAmber.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(ControlCenterTokens.Colors.accentAmber.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    // MARK: - Actions
    private func sendTextMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (!text.isEmpty || !attachedImages.isEmpty), !sessionManager.isProcessing else { return }

        let currentAttached = attachedImages
        let imagePaths = currentAttached.isEmpty ? nil : currentAttached.map { $0.filePath }
        let userImages = currentAttached.map { UserImageAttachment(data: $0.data, mimeType: $0.mimeType) }

        inputText = ""
        attachedImages = []

        _Concurrency.Task {
            await sessionManager.processPrompt(
                text: text,
                isVoice: false,
                imagePaths: imagePaths,
                userImages: userImages
            )
        }
    }

    private func toggleChatMic() {
        if isRecordingVoice {
            isRecordingVoice = false
            AudioCaptureService.shared.stopCapture()
            SpeechRecognitionRouter.shared.stopRecognition { finalTranscript in
                _Concurrency.Task { @MainActor in
                    if !finalTranscript.isEmpty {
                        self.inputText = finalTranscript
                    }

                    let text = self.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard (!text.isEmpty || !self.attachedImages.isEmpty) else {
                        self.inputText = ""
                        return
                    }

                    let currentAttached = self.attachedImages
                    let imagePaths = currentAttached.isEmpty ? nil : currentAttached.map { $0.filePath }
                    let userImages = currentAttached.map { UserImageAttachment(data: $0.data, mimeType: $0.mimeType) }

                    self.inputText = ""
                    self.attachedImages = []

                    await self.sessionManager.processPrompt(
                        text: text,
                        isVoice: true,
                        imagePaths: imagePaths,
                        userImages: userImages
                    )
                }
            }
        } else {
            isRecordingVoice = true
            inputText = ""
            do {
                try SpeechRecognitionRouter.shared.startRecognition { liveText, isFinal in
                    _Concurrency.Task { @MainActor in
                        if !liveText.isEmpty {
                            self.inputText = liveText
                        }
                    }
                }
                try AudioCaptureService.shared.startCapture { buffer in
                    SpeechRecognitionRouter.shared.appendAudioBuffer(buffer)
                }
            } catch {
                isRecordingVoice = false
            }
        }
    }

    // MARK: - Clipboard Paste & Image Attachments
    @discardableResult
    private func handlePasteImageFromClipboard() -> Bool {
        let pasteboard = NSPasteboard.general
        guard let types = pasteboard.types, !types.isEmpty else { return false }

        let imageTypes: [NSPasteboard.PasteboardType] = [
            .png,
            .tiff,
            NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("public.heic")
        ]

        if types.contains(where: { imageTypes.contains($0) }) {
            // 1. Direct PNG
            if let pngData = pasteboard.data(forType: .png),
               let image = NSImage(data: pngData) {
                return attachImageData(pngData, mimeType: "image/png", previewImage: image)
            }

            // 2. NSImage bitmap representation (converts TIFF / screenshots to JPEG)
            if let image = NSImage(pasteboard: pasteboard),
               let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData) {
                let quality: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: 0.85]
                if let jpegData = bitmap.representation(using: .jpeg, properties: quality) {
                    return attachImageData(jpegData, mimeType: "image/jpeg", previewImage: image)
                }
            }
        }

        // 3. File URLs copied from Finder (e.g. ⌘C on image files)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            var anyAttached = false
            for url in urls {
                guard url.isFileURL else { continue }
                let ext = url.pathExtension.lowercased()
                let supportedImageExts = ["png", "jpg", "jpeg", "webp", "gif", "heic", "tiff"]
                if supportedImageExts.contains(ext),
                   let data = try? Data(contentsOf: url),
                   let image = NSImage(contentsOf: url) {
                    let mime: String
                    switch ext {
                    case "png": mime = "image/png"
                    case "webp": mime = "image/webp"
                    case "gif": mime = "image/gif"
                    default: mime = "image/jpeg"
                    }
                    if attachImageData(data, mimeType: mime, previewImage: image) {
                        anyAttached = true
                    }
                }
            }
            if anyAttached { return true }
        }

        return false
    }

    private func attachImageData(_ data: Data, mimeType: String, previewImage: NSImage) -> Bool {
        if attachedImages.contains(where: { $0.data == data }) {
            return false
        }

        let ext = mimeType == "image/png" ? "png" : (mimeType == "image/webp" ? "webp" : "jpg")
        guard let savedPath = saveAttachmentFile(data: data, ext: ext) else { return false }

        let item = AttachedImageItem(
            id: UUID().uuidString,
            filePath: savedPath,
            thumbnail: previewImage,
            data: data,
            mimeType: mimeType
        )

        withAnimation(ControlCenterTokens.Motion.snappy) {
            attachedImages.append(item)
        }
        return true
    }

    private func saveAttachmentFile(data: Data, ext: String) -> String? {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let attachmentsDir = appSupport.appendingPathComponent("Aura/Attachments", isDirectory: true)
        do {
            try fileManager.createDirectory(at: attachmentsDir, withIntermediateDirectories: true)
            let filename = "attachment_\(UUID().uuidString).\(ext)"
            let fileURL = attachmentsDir.appendingPathComponent(filename)
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            return nil
        }
    }

    private func formattedByteCount(_ bytes: Int) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(bytes))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// Expandable card representing an autonomous tool call, styled as a dark terminal component.
public struct ToolCallCardView: View {
    public let toolCall: ToolCallRecord
    @State private var isExpanded: Bool = false

    public init(toolCall: ToolCallRecord) {
        self.toolCall = toolCall
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(ControlCenterTokens.Motion.snappy) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 10)

                    ZStack {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(ControlCenterTokens.Colors.accentPurple.opacity(0.2))
                            .frame(width: 20, height: 20)

                        Image(systemName: iconForTool(toolCall.toolName))
                            .foregroundColor(ControlCenterTokens.Colors.accentPurple)
                            .font(.system(size: 10))
                    }

                    Text(toolCall.toolName)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)

                    if toolCall.latencyMs > 0 {
                        Text("\(toolCall.latencyMs)ms")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))
                    }

                    Spacer()

                    // Status Pill
                    HStack(spacing: 4) {
                        if toolCall.status == .running {
                            ProgressView()
                                .controlSize(.mini)
                                .scaleEffect(0.65)
                        } else {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 5, height: 5)
                        }
                        Text(statusText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(statusColor)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(statusColor.opacity(0.12))
                    .cornerRadius(4)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(ControlCenterTokens.Colors.glassSurface)
            }
            .buttonStyle(.plain)

            // Collapsible Details
            if isExpanded {
                Divider()
                    .overlay(Color.white.opacity(0.06))

                VStack(alignment: .leading, spacing: 10) {
                    if !toolCall.argumentsJson.isEmpty && toolCall.argumentsJson != "{}" {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("INPUT ARGUMENTS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                            ParsedArgumentsView(jsonString: toolCall.argumentsJson)
                        }
                    }

                    if !toolCall.output.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("TOOL OUTPUT")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))

                                if isLongOutput {
                                    Text("(\(toolCall.output.components(separatedBy: "\n").count) lines)")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.35))
                                }

                                Spacer()

                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(toolCall.output, forType: .string)
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }

                            // Inline Image Preview (Async background cached, standardized 360x180 frame)
                            if let imgPath = resolvedImagePath {
                                ToolCallImagePreviewView(imagePath: imgPath)
                            }

                            // Output Text
                            if !cleanOutputText.isEmpty {
                                if isLongOutput {
                                    ScrollView(.vertical, showsIndicators: true) {
                                        Text(cleanOutputText)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.85))
                                            .padding(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxHeight: 180)
                                    .background(ControlCenterTokens.Colors.sunkenSurface)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                } else {
                                    Text(cleanOutputText)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.85))
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(ControlCenterTokens.Colors.sunkenSurface)
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .background(ControlCenterTokens.Colors.sunkenSurface.opacity(0.5))
            }
        }
        .cornerRadius(ControlCenterTokens.Radii.innerCard)
        .overlay(
            RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.innerCard)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var resolvedImagePath: String? {
        if let path = toolCall.imagePath, FileManager.default.fileExists(atPath: path) {
            return path
        }
        // Fallback: detect path from output if imagePath wasn't saved in older records
        let out = toolCall.output
        if let range = out.range(of: #"(?:Saved to |screenshot saved to\s*)(/[^\n\r]+?\.(?:png|jpg|jpeg|webp|bmp|heic))"#, options: [.regularExpression, .caseInsensitive]) {
            let match = String(out[range])
            if let slashRange = match.range(of: #"/.*"#, options: .regularExpression) {
                let path = String(match[slashRange]).trimmingCharacters(in: CharacterSet(charactersIn: " .,"))
                if FileManager.default.fileExists(atPath: path) {
                    return path
                }
            }
        }
        if let range = out.range(of: #"((?:/Users|/tmp|/var|/private)[^\n\r]+?\.(?:png|jpg|jpeg|webp|bmp|heic))"#, options: [.regularExpression, .caseInsensitive]) {
            let path = String(out[range]).trimmingCharacters(in: CharacterSet(charactersIn: " .,"))
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    private var cleanOutputText: String {
        toolCall.output
            .replacingOccurrences(of: ". Visual pixels attached below:", with: ".")
            .replacingOccurrences(of: ". Visual pixels attached below", with: ".")
            .replacingOccurrences(of: "Visual pixels attached below:", with: "")
            .replacingOccurrences(of: "Visual pixels attached below", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isLongOutput: Bool {
        cleanOutputText.components(separatedBy: "\n").count > 5 || cleanOutputText.count > 350
    }

    private var statusColor: Color {
        switch toolCall.status {
        case .running: return ControlCenterTokens.Colors.accentCyan
        case .success: return ControlCenterTokens.Colors.accentEmerald
        case .failure: return Color.red
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
        case "view_image": return "photo.fill"
        case "list_files": return "folder.fill"
        case "execute_terminal_command": return "terminal.fill"
        case "search_emails": return "envelope.fill"
        case "query_notion": return "doc.text.fill"
        default: return "gearshape.fill"
        }
    }
}

/// Renders structured tool call arguments as clean, readable key-value blocks.
public struct ParsedArgumentsView: View {
    public let jsonString: String

    public init(jsonString: String) {
        self.jsonString = jsonString
    }

    private var parsedDictionary: [(key: String, displayValue: String)]? {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              !dict.isEmpty else {
            return nil
        }

        return dict.sorted(by: { $0.key < $1.key }).map { (key: $0.key, displayValue: formatValue($0.value)) }
    }

    private func formatValue(_ value: Any) -> String {
        if let str = value as? String {
            return str.replacingOccurrences(of: "\\/", with: "/")
        }
        if let num = value as? NSNumber {
            return num.stringValue
        }
        if let bool = value as? Bool {
            return bool ? "true" : "false"
        }
        if let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .withoutEscapingSlashes]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "\(value)"
    }

    public var body: some View {
        if let entries = parsedDictionary, !entries.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entries, id: \.key) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(entry.key)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(ControlCenterTokens.Colors.accentPurple)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1.5)
                                .background(ControlCenterTokens.Colors.accentPurple.opacity(0.18))
                                .cornerRadius(3)
                            Spacer()
                        }

                        Text(entry.displayValue)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ControlCenterTokens.Colors.sunkenSurface)
                            .cornerRadius(4)
                    }
                }
            }
        } else {
            Text(cleanFallbackString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ControlCenterTokens.Colors.sunkenSurface)
                .cornerRadius(4)
        }
    }

    private var cleanFallbackString: String {
        jsonString.replacingOccurrences(of: "\\/", with: "/")
    }
}
