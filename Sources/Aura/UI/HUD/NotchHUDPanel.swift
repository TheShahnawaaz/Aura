import AppKit
import SwiftUI
import Combine

/// Floating, non-activating NSPanel that anchors to the top screen edge and spans the MacBook camera notch.
@MainActor
public final class NotchHUDPanel: NSPanel {
    public let geometry: NotchGeometry
    private var cancellables = Set<AnyCancellable>()

    public init(geometry: NotchGeometry = NotchGeometry(), appState: AppState = .shared) {
        self.geometry = geometry

        let initialRect = NSRect(
            x: 0,
            y: 0,
            width: geometry.closedWidth,
            height: geometry.notchHeight
        )

        super.init(
            contentRect: initialRect,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )

        // Panel characteristics
        self.isFloatingPanel = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovable = false
        self.hidesOnDeactivate = false
        self.level = .screenSaver
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        // Hosting view with NotchHUDView
        let contentView = NSHostingView(
            rootView: NotchHUDView(appState: appState, geometry: geometry)
        )
        contentView.sizingOptions = []
        self.contentView = contentView

        reposition()
        observeScreenChanges()
        setupDismissalMonitors(appState: appState)
    }

    private var clickAwayMonitor: Any? = nil
    private var escapeLocalMonitor: Any? = nil
    private var escapeGlobalMonitor: Any? = nil

    private func setupDismissalMonitors(appState: AppState) {
        appState.$isTurnCompletedPresented
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPresented in
                if isPresented {
                    self?.startDismissalMonitors(appState: appState)
                } else {
                    self?.stopDismissalMonitors()
                }
            }
            .store(in: &cancellables)
    }

    private func startDismissalMonitors(appState: AppState) {
        stopDismissalMonitors()

        // 1. Global click-away: detect click outside the Notch
        clickAwayMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self else { return }
            let clickLocation = NSEvent.mouseLocation
            // If click occurs outside the notch HUD window frame
            if !self.frame.contains(clickLocation) {
                Task { @MainActor in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        appState.dismissTurnCompleted()
                    }
                }
            }
        }

        // 2. Global Escape key detection
        escapeGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC key
                Task { @MainActor in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        appState.dismissTurnCompleted()
                    }
                }
            }
        }

        // 3. Local Escape key detection
        escapeLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                Task { @MainActor in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        appState.dismissTurnCompleted()
                    }
                }
                return nil
            }
            return event
        }
    }

    private func stopDismissalMonitors() {
        if let monitor = clickAwayMonitor {
            NSEvent.removeMonitor(monitor)
            clickAwayMonitor = nil
        }
        if let monitor = escapeGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            escapeGlobalMonitor = nil
        }
        if let monitor = escapeLocalMonitor {
            NSEvent.removeMonitor(monitor)
            escapeLocalMonitor = nil
        }
    }

    override public var canBecomeKey: Bool { false }
    override public var canBecomeMain: Bool { false }

    /// Repositions the panel to sit flush against the top edge of the primary display.
    public func reposition() {
        guard let screen = NSScreen.main else { return }
        geometry.update(for: screen)

        let screenFrame = screen.frame
        let panelWidth: CGFloat = 650 // Max bounding frame width
        let panelHeight: CGFloat = min(850, screenFrame.height - 80) // Max bounding dropdown height for large tool outputs

        let x = geometry.notchCenterX - (panelWidth / 2)
        let y = screenFrame.maxY - panelHeight

        setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
    }

    private func observeScreenChanges() {
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reposition()
            }
            .store(in: &cancellables)
    }
}
