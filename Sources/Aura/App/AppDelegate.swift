import AppKit
import SwiftUI
import Combine

/// Application delegate managing the macOS life cycle, Dock presence, and global hotkeys.
@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) weak var shared: AppDelegate?

    public private(set) var hudPanel: NotchHUDPanel?
    public private(set) var settingsController: SettingsWindowController?
    public private(set) var statusBarController: StatusBarController?

    private let appState = AppState.shared
    private let hotkeyManager = HotkeyManager.shared
    private let audioCapture = AudioCaptureService.shared
    private let speechSynthesizer = SpeechSynthesizer.shared
    private let speechRecognitionRouter = SpeechRecognitionRouter.shared

    private var dockHostingView: NSView?
    private var dockAnimationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    public override init() {
        super.init()
        AppDelegate.shared = self
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Configure as a standard Dock application
        NSApplication.shared.setActivationPolicy(.regular)

        // Setup live interactive Dock icon with Living Aurora Orb
        setupLiveDockIcon()
        observeAppStateForDock()

        // Request Speech Recognition permission upfront
        NativeSpeechRecognizer.requestAuthorization()

        // Initialize and position the Notch HUD floating panel
        let panel = NotchHUDPanel(appState: appState)
        self.hudPanel = panel
        panel.orderFrontRegardless()

        // Initialize and show the Settings window on launch
        let settings = SettingsWindowController.shared
        self.settingsController = settings
        settings.showSettings()

        // Setup system menu bar status item
        self.statusBarController = StatusBarController(appState: appState) { [weak self] in
            self?.handleHotKeyToggle()
        }

        // Setup global shortcut listener
        setupHotkey()
    }

    // MARK: - Live macOS Dock Icon
    private func setupLiveDockIcon() {
        guard UserDefaults.standard.object(forKey: "enableLiveDockIcon") == nil || UserDefaults.standard.bool(forKey: "enableLiveDockIcon") else {
            return
        }
        // Apple HIG macOS icon grid: 104pt squircle centered inside 128pt tile
        let orbView = ZStack {
            Color.clear
            LivingAuroraOrbView(appState: appState, size: 76, showSquircleBackground: true)
        }
        .frame(width: 128, height: 128)

        let hosting = NSHostingView(rootView: AnyView(orbView))
        hosting.frame = NSRect(x: 0, y: 0, width: 128, height: 128)
        self.dockHostingView = hosting
        NSApplication.shared.dockTile.contentView = hosting
        NSApplication.shared.dockTile.display()
    }

    private func observeAppStateForDock() {
        appState.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.handleStateChangeForDock(newState)
            }
            .store(in: &cancellables)

        // Throttle live audio levels to ~30fps for smooth visual wave rendering while listening
        appState.$audioLevel
            .throttle(for: .milliseconds(33), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                if self?.appState.state == .listening {
                    self?.refreshDockTile()
                }
            }
            .store(in: &cancellables)
    }

    private func handleStateChangeForDock(_ state: AssistantState) {
        dockAnimationTimer?.invalidate()
        dockAnimationTimer = nil

        refreshDockTile()

        switch state {
        case .processing, .speaking:
            // Sync live 30 FPS animation in the Dock while vortex / harmonic ribbon is active
            dockAnimationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshDockTile()
                }
            }
        case .idle, .listening, .awaitingConfirmation, .error:
            break
        }
    }

    public func refreshDockTile() {
        let isEnabled = UserDefaults.standard.object(forKey: "enableLiveDockIcon") == nil || UserDefaults.standard.bool(forKey: "enableLiveDockIcon")
        if !isEnabled {
            dockAnimationTimer?.invalidate()
            dockAnimationTimer = nil
            if NSApplication.shared.dockTile.contentView != nil {
                NSApplication.shared.dockTile.contentView = nil
                NSApplication.shared.dockTile.display()
            }
            return
        }

        if dockHostingView == nil {
            setupLiveDockIcon()
        }
        NSApplication.shared.dockTile.display()
    }

    private func setupHotkey() {
        hotkeyManager.registerDefaultHotkey { [weak self] in
            Task { @MainActor in
                self?.handleHotKeyToggle()
            }
        }
    }

    /// Toggles voice interaction when the user presses the global shortcut.
    public func handleHotKeyToggle() {
        switch appState.state {
        case .idle, .error:
            startVoiceSession()

        case .listening:
            submitVoiceSession()

        case .speaking:
            // Barge-in: immediately silence audio and return to listening
            speechSynthesizer.stopSpeaking()
            startVoiceSession()

        case .processing, .awaitingConfirmation:
            // Cancel current processing
            audioCapture.stopCapture()
            speechRecognitionRouter.cancelRecognition()
            appState.resetToIdle()
        }
    }

    /// Immediately discards or closes any in-progress listening or speaking session, or active modal/HUD event.
    public func cancelOrDiscardActiveEvent() {
        silenceTask?.cancel()
        silenceTask = nil

        switch appState.state {
        case .listening:
            audioCapture.stopCapture()
            speechRecognitionRouter.cancelRecognition()
            AudioDuckingManager.shared.unduckMedia()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                appState.resetToIdle()
            }

        case .speaking:
            speechSynthesizer.stopSpeaking()
            AudioDuckingManager.shared.unduckMedia()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                appState.resetToIdle()
            }

        case .processing, .awaitingConfirmation, .error:
            audioCapture.stopCapture()
            speechRecognitionRouter.cancelRecognition()
            speechSynthesizer.stopSpeaking()
            AudioDuckingManager.shared.unduckMedia()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                appState.resetToIdle()
            }

        case .idle:
            if appState.isTurnCompletedPresented {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    appState.dismissTurnCompleted()
                }
            }
        }
    }

    private var lastSpeechTime: Date = Date()
    private var silenceTask: Task<Void, Never>?

    private func startVoiceSession() {
        appState.startListening()
        lastSpeechTime = Date()
        silenceTask?.cancel()

        do {
            try speechRecognitionRouter.startRecognition { [weak self] liveTranscript, isFinal in
                Task { @MainActor in
                    guard let self else { return }
                    if !liveTranscript.isEmpty {
                        self.appState.partialTranscript = liveTranscript
                        self.appState.transcript = liveTranscript
                        self.lastSpeechTime = Date()
                    }
                    self.scheduleSilenceCheckIfNeeded()
                }
            }

            try audioCapture.startCapture { [weak self] buffer in
                guard let self else { return }
                self.speechRecognitionRouter.appendAudioBuffer(buffer)
                let level = AudioCaptureService.calculateRMS(buffer: buffer)
                if level > 0.05 {
                    Task { @MainActor in
                        self.lastSpeechTime = Date()
                        self.scheduleSilenceCheckIfNeeded()
                    }
                }
            }
        } catch {
            appState.state = .error(message: error.localizedDescription)
        }
    }

    private func scheduleSilenceCheckIfNeeded() {
        guard UserDefaults.standard.bool(forKey: "autoSubmitOnSilence") else { return }
        let threshold = UserDefaults.standard.object(forKey: "silenceDuration") != nil ? UserDefaults.standard.double(forKey: "silenceDuration") : 1.8

        silenceTask?.cancel()
        silenceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(threshold * 1_000_000_000))
            if !Task.isCancelled, self.appState.state == .listening {
                self.submitVoiceSession()
            }
        }
    }

    private func submitVoiceSession() {
        silenceTask?.cancel()
        silenceTask = nil

        audioCapture.stopCapture()
        appState.stopListeningAndProcess()

        speechRecognitionRouter.stopRecognition { [weak self] finalTranscript in
            Task { @MainActor in
                guard let self else { return }
                if !finalTranscript.isEmpty {
                    self.appState.transcript = finalTranscript
                }

                let userPrompt = self.appState.transcript.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !userPrompt.isEmpty else {
                    self.appState.state = .error(message: "No speech recognized. Please try again.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                        self?.appState.resetToIdle()
                    }
                    return
                }

                let answer = await AgentSessionManager.shared.processPrompt(text: userPrompt, isVoice: true)
                self.appState.responseText = answer
            }
        }
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in the background when the 3-tab Settings window is closed
        return false
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Reopen the 3-tab Settings window when clicking the Dock icon
        settingsController?.showSettings()
        return true
    }

    public func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
        audioCapture.stopCapture()
        speechRecognitionRouter.cancelRecognition()
    }
}
