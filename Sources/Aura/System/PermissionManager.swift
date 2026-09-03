import AppKit
import AVFoundation

/// Manages system permission checks and user authorization requests.
@MainActor
public final class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()

    @Published public var hasMicrophonePermission: Bool = false
    @Published public var hasAccessibilityPermission: Bool = false

    public init() {
        checkAllPermissions()
    }

    /// Checks the current authorization status for all required system services.
    public func checkAllPermissions() {
        checkMicrophonePermission()
        checkAccessibilityPermission()
    }

    /// Checks and requests microphone access.
    public func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            hasMicrophonePermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                Task { @MainActor in
                    self?.hasMicrophonePermission = granted
                }
            }
        default:
            hasMicrophonePermission = false
        }
    }

    /// Checks macOS Accessibility trust status (AXIsProcessTrusted).
    public func checkAccessibilityPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    /// Prompts the user to grant Accessibility permissions in System Settings.
    public func requestAccessibilityPermission() {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: true] as CFDictionary
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
    }
}
