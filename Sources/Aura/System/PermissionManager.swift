import AppKit
import ApplicationServices
import AVFoundation
import CoreGraphics
import Foundation
import Speech

public enum PermissionType: String, CaseIterable, Identifiable, Sendable {
    case accessibility = "Accessibility"
    case screenRecording = "Screen Recording"
    case microphone = "Microphone"
    case speechRecognition = "Speech Recognition"
    case appleEvents = "Automation (AppleEvents)"
    case fullDiskAccess = "Full Disk Access"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .accessibility: return "hand.tap.fill"
        case .screenRecording: return "rectangle.dashed.badge.record"
        case .microphone: return "mic.fill"
        case .speechRecognition: return "waveform"
        case .appleEvents: return "applescript.fill"
        case .fullDiskAccess: return "internaldrive.fill"
        }
    }

    public var description: String {
        switch self {
        case .accessibility:
            return "Allows Aura to observe UI elements, simulate clicks, and type into applications."
        case .screenRecording:
            return "Allows Aura to inspect visible screen state and capture screenshots on demand."
        case .microphone:
            return "Allows Aura to capture audio for real-time voice conversations."
        case .speechRecognition:
            return "Transcribes your speech on-device into text for quick command processing."
        case .appleEvents:
            return "Enables direct scripting control of native apps like Notes, Safari, and Finder."
        case .fullDiskAccess:
            return "Allows inspecting developer files and repositories without sandbox restrictions."
        }
    }

    public var settingsURL: URL? {
        switch self {
        case .accessibility:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        case .screenRecording:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        case .microphone:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
        case .speechRecognition:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")
        case .appleEvents:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
        case .fullDiskAccess:
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
        }
    }
}

public enum PermissionStatus: String, Sendable {
    case granted = "Granted"
    case notDetermined = "Action Required"
    case denied = "Denied"

    public var badgeColor: String {
        switch self {
        case .granted: return "green"
        case .notDetermined: return "orange"
        case .denied: return "red"
        }
    }
}

/// Central manager and observer for all macOS system permissions required by Aura.
@MainActor
public final class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()

    @Published public var accessibilityStatus: PermissionStatus = .notDetermined
    @Published public var screenRecordingStatus: PermissionStatus = .notDetermined
    @Published public var microphoneStatus: PermissionStatus = .notDetermined
    @Published public var speechRecognitionStatus: PermissionStatus = .notDetermined
    @Published public var appleEventsStatus: PermissionStatus = .notDetermined
    @Published public var fullDiskAccessStatus: PermissionStatus = .notDetermined

    // Backwards compatibility properties
    public var hasAccessibilityPermission: Bool { accessibilityStatus == .granted }
    public var hasMicrophonePermission: Bool { microphoneStatus == .granted }

    public init() {
        refreshAll()
    }

    /// Checks the current authorization status for all required system services.
    public func checkAllPermissions() {
        refreshAll()
    }

    /// Queries live macOS system APIs to refresh all authorization states.
    public func refreshAll() {
        // 1. Accessibility
        if AXIsProcessTrusted() {
            accessibilityStatus = .granted
        } else {
            accessibilityStatus = .notDetermined
        }

        // 2. Screen Recording
        if CGPreflightScreenCaptureAccess() {
            screenRecordingStatus = .granted
        } else {
            screenRecordingStatus = .notDetermined
        }

        // 3. Microphone
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneStatus = .granted
        case .notDetermined:
            microphoneStatus = .notDetermined
        case .denied, .restricted:
            microphoneStatus = .denied
        @unknown default:
            microphoneStatus = .notDetermined
        }

        // 4. Speech Recognition
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechRecognitionStatus = .granted
        case .notDetermined:
            speechRecognitionStatus = .notDetermined
        case .denied, .restricted:
            speechRecognitionStatus = .denied
        @unknown default:
            speechRecognitionStatus = .notDetermined
        }

        // 5. AppleEvents (Test benign AppleEvent query)
        let script = "tell application \"System Events\" to get name"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            _ = appleScript.executeAndReturnError(&error)
            if error == nil {
                appleEventsStatus = .granted
            } else {
                appleEventsStatus = .notDetermined
            }
        }

        // 6. Full Disk Access (Test directory access to protected folders)
        let protectedPaths = [
            ("~/Library/Safari" as NSString).expandingTildeInPath,
            ("~/Library/Mail" as NSString).expandingTildeInPath,
            ("~/Library/Suggestions" as NSString).expandingTildeInPath
        ]
        var hasAccess = false
        for path in protectedPaths {
            if FileManager.default.fileExists(atPath: path) {
                if let _ = try? FileManager.default.contentsOfDirectory(atPath: path) {
                    hasAccess = true
                    break
                }
            }
        }
        fullDiskAccessStatus = hasAccess ? .granted : .notDetermined
    }

    public func status(for type: PermissionType) -> PermissionStatus {
        switch type {
        case .accessibility: return accessibilityStatus
        case .screenRecording: return screenRecordingStatus
        case .microphone: return microphoneStatus
        case .speechRecognition: return speechRecognitionStatus
        case .appleEvents: return appleEventsStatus
        case .fullDiskAccess: return fullDiskAccessStatus
        }
    }

    /// Triggers system prompt or requests access for a specific permission.
    public func requestAccess(for type: PermissionType) {
        switch type {
        case .accessibility:
            let promptKey = "AXTrustedCheckOptionPrompt" as CFString
            let options = [promptKey: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            refreshAll()
            if accessibilityStatus != .granted, let url = type.settingsURL {
                NSWorkspace.shared.open(url)
            }

        case .screenRecording:
            _ = CGRequestScreenCaptureAccess()
            refreshAll()
            if screenRecordingStatus != .granted, let url = type.settingsURL {
                NSWorkspace.shared.open(url)
            }

        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { @Sendable _ in
                DispatchQueue.main.async {
                    PermissionManager.shared.refreshAll()
                }
            }

        case .speechRecognition:
            SFSpeechRecognizer.requestAuthorization { @Sendable _ in
                DispatchQueue.main.async {
                    PermissionManager.shared.refreshAll()
                }
            }

        case .appleEvents:
            if let url = type.settingsURL {
                NSWorkspace.shared.open(url)
            }

        case .fullDiskAccess:
            // Proactively attempt reading protected path so macOS populates Aura.app in the Full Disk Access list
            let testPath = ("~/Library/Safari" as NSString).expandingTildeInPath
            _ = try? FileManager.default.contentsOfDirectory(atPath: testPath)
            if let url = type.settingsURL {
                NSWorkspace.shared.open(url)
            }
        }
    }

    /// Requests all permissions sequentially, triggering system prompts.
    public func requestAll() {
        requestAccess(for: .accessibility)
        requestAccess(for: .screenRecording)
        requestAccess(for: .microphone)
        requestAccess(for: .speechRecognition)
    }

    /// Prompts the user to grant Accessibility permissions in System Settings.
    public func requestAccessibilityPermission() {
        requestAccess(for: .accessibility)
    }

    /// Opens System Settings directly to the corresponding privacy pane.
    public func openSettings(for type: PermissionType) {
        if let url = type.settingsURL {
            NSWorkspace.shared.open(url)
        }
    }

    public var grantedCount: Int {
        PermissionType.allCases.filter { status(for: $0) == .granted }.count
    }
}
