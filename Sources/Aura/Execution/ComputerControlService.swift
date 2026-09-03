import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import ImageIO

/// Revision-scoped, accessibility-first macOS control. Element identifiers are valid only
/// for the observation that produced them, preventing the agent from acting on stale UI.
public final class ComputerControlService: @unchecked Sendable {
    public static let shared = ComputerControlService()

    private let lock = NSLock()
    private var revision = UUID().uuidString
    private var elements: [String: AXUIElement] = [:]
    private var nextElementIndex = 0

    private init() {}

    public func observe(appBundleId: String? = nil) throws -> String {
        guard AXIsProcessTrusted() else {
            let promptKey = "AXTrustedCheckOptionPrompt" as CFString
            let options = [promptKey: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            throw ComputerControlError.accessibilityPermissionRequired
        }

        let application = try resolveApplication(bundleId: appBundleId)
        let root = AXUIElementCreateApplication(application.processIdentifier)

        lock.lock()
        revision = UUID().uuidString
        elements.removeAll()
        nextElementIndex = 0
        let currentRevision = revision
        lock.unlock()

        let rootNode = snapshot(element: root, depth: 0, revision: currentRevision)
        let payload = ComputerObservation(
            revision: currentRevision,
            appBundleId: application.bundleIdentifier ?? "",
            appName: application.localizedName ?? application.bundleIdentifier ?? "Unknown app",
            pid: application.processIdentifier,
            root: rootNode
        )
        return try encode(payload)
    }

    public func click(elementId: String) throws -> String {
        let element = try resolvedElement(elementId)
        let error = AXUIElementPerformAction(element, kAXPressAction as CFString)
        guard error == .success else { throw ComputerControlError.actionFailed("press", error) }
        return "Pressed \(elementId). Re-observe before the next UI action."
    }

    public func setValue(elementId: String, value: String) throws -> String {
        let element = try resolvedElement(elementId)
        let error = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, value as CFTypeRef)
        guard error == .success else { throw ComputerControlError.actionFailed("set value", error) }
        return "Updated \(elementId). Re-observe before the next UI action."
    }

    public func pressKeys(_ keys: [String]) throws -> String {
        guard AXIsProcessTrusted() else {
            let promptKey = "AXTrustedCheckOptionPrompt" as CFString
            let options = [promptKey: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            throw ComputerControlError.accessibilityPermissionRequired
        }
        let modifiers = keyModifiers(from: keys)
        let keyNames = keys.filter { !["cmd", "command", "ctrl", "control", "option", "alt", "shift"].contains($0.lowercased()) }
        guard keyNames.count == 1, let keyCode = keyCode(for: keyNames[0]) else {
            throw ComputerControlError.invalidKeyCombination(keys)
        }
        guard let source = CGEventSource(stateID: .hidSystemState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            throw ComputerControlError.eventCreationFailed
        }
        down.flags = modifiers
        up.flags = modifiers
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return "Pressed \(keys.joined(separator: "+")). Re-observe before the next UI action."
    }

    public func scroll(direction: String, amount: Int = 3) throws -> String {
        let delta = (direction.lowercased() == "up" || direction.lowercased() == "left") ? amount : -amount
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: Int32(delta), wheel2: 0, wheel3: 0) else {
            throw ComputerControlError.eventCreationFailed
        }
        event.post(tap: .cghidEventTap)
        return "Scrolled \(direction). Re-observe before the next UI action."
    }

    public func takeScreenshot() throws -> String {
        if !CGPreflightScreenCaptureAccess() {
            _ = CGRequestScreenCaptureAccess()
        }
        guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
            throw ComputerControlError.screenshotFailed
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("AuraScreenshots", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("Aura-\(UUID().uuidString).png")
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw ComputerControlError.screenshotFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw ComputerControlError.screenshotFailed }
        return "Screenshot saved to \(url.path)"
    }

    private func resolveApplication(bundleId: String?) throws -> NSRunningApplication {
        if let bundleId, !bundleId.isEmpty {
            guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) else {
                throw ComputerControlError.applicationNotRunning(bundleId)
            }
            return app
        }
        guard let app = NSWorkspace.shared.frontmostApplication else { throw ComputerControlError.noFrontmostApplication }
        return app
    }

    private func snapshot(element: AXUIElement, depth: Int, revision: String) -> ComputerElement {
        let id = register(element: element, revision: revision)
        let children = depth < 5 ? (attribute(element, kAXChildrenAttribute) as? [AXUIElement] ?? []).prefix(120).map {
            snapshot(element: $0, depth: depth + 1, revision: revision)
        } : []
        return ComputerElement(
            id: id,
            role: stringAttribute(element, kAXRoleAttribute) ?? "unknown",
            title: stringAttribute(element, kAXTitleAttribute),
            value: displayValue(attribute(element, kAXValueAttribute)),
            label: stringAttribute(element, kAXDescriptionAttribute) ?? stringAttribute(element, kAXHelpAttribute),
            enabled: boolAttribute(element, kAXEnabledAttribute),
            actions: actions(element),
            children: Array(children)
        )
    }

    private func register(element: AXUIElement, revision: String) -> String {
        lock.lock(); defer { lock.unlock() }
        let id = "\(revision):\(nextElementIndex)"
        nextElementIndex += 1
        elements[id] = element
        return id
    }

    private func resolvedElement(_ id: String) throws -> AXUIElement {
        lock.lock(); defer { lock.unlock() }
        guard id.hasPrefix("\(revision):"), let element = elements[id] else { throw ComputerControlError.staleElement(id) }
        return element
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
    }

    private func stringAttribute(_ element: AXUIElement, _ name: String) -> String? { attribute(element, name) as? String }
    private func boolAttribute(_ element: AXUIElement, _ name: String) -> Bool? { attribute(element, name) as? Bool }
    private func displayValue(_ value: AnyObject?) -> String? {
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }
    private func actions(_ element: AXUIElement) -> [String] {
        var names: CFArray?
        guard AXUIElementCopyActionNames(element, &names) == .success, let actions = names as? [String] else { return [] }
        return actions
    }

    private func keyModifiers(from keys: [String]) -> CGEventFlags {
        keys.reduce([]) { flags, key in
            switch key.lowercased() {
            case "cmd", "command": return flags.union(.maskCommand)
            case "ctrl", "control": return flags.union(.maskControl)
            case "option", "alt": return flags.union(.maskAlternate)
            case "shift": return flags.union(.maskShift)
            default: return flags
            }
        }
    }

    private func keyCode(for key: String) -> CGKeyCode? {
        let mapping: [String: CGKeyCode] = [
            "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3, "g": 5, "h": 4, "i": 34, "j": 38, "k": 40, "l": 37, "m": 46, "n": 45, "o": 31, "p": 35, "q": 12, "r": 15, "s": 1, "t": 17, "u": 32, "v": 9, "w": 13, "x": 7, "y": 16, "z": 6,
            "return": 36, "enter": 36, "escape": 53, "tab": 48, "space": 49, "delete": 51,
            "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26, "8": 28, "9": 25
        ]
        return mapping[key.lowercased()]
    }

    private func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }
}

public struct ComputerObservation: Codable, Sendable {
    public let revision: String
    public let appBundleId: String
    public let appName: String
    public let pid: pid_t
    public let root: ComputerElement
}

public struct ComputerElement: Codable, Sendable {
    public let id: String
    public let role: String
    public let title: String?
    public let value: String?
    public let label: String?
    public let enabled: Bool?
    public let actions: [String]
    public let children: [ComputerElement]
}

public enum ComputerControlError: LocalizedError {
    case accessibilityPermissionRequired
    case applicationNotRunning(String)
    case noFrontmostApplication
    case staleElement(String)
    case actionFailed(String, AXError)
    case invalidKeyCombination([String])
    case eventCreationFailed
    case screenshotFailed

    public var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired: return "Aura needs Accessibility permission. Enable it in System Settings > Privacy & Security > Accessibility."
        case .applicationNotRunning(let id): return "No running application matches \(id)."
        case .noFrontmostApplication: return "No frontmost application is available."
        case .staleElement: return "That UI element belongs to an old observation. Run computer.observe again."
        case .actionFailed(let action, let error): return "Unable to \(action) the UI element (AXError \(error.rawValue))."
        case .invalidKeyCombination(let keys): return "Unsupported key combination: \(keys.joined(separator: "+"))."
        case .eventCreationFailed: return "Unable to create the input event."
        case .screenshotFailed: return "Unable to capture a screenshot. Screen Recording permission may be required."
        }
    }
}
