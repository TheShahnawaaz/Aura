import AppKit
import Carbon

/// Pre-configured selectable global shortcut options.
public enum HotkeyOption: String, CaseIterable, Identifiable, Sendable {
    case optionSpace = "option_space"
    case controlSpace = "control_space"
    case shiftOptionSpace = "shift_option_space"
    case commandShiftSpace = "command_shift_space"
    case optionA = "option_a"
    case controlA = "control_a"
    case commandShiftA = "command_shift_a"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .optionSpace: return "⌥ Space (Option + Space)"
        case .controlSpace: return "⌃ Space (Control + Space)"
        case .shiftOptionSpace: return "⇧ ⌥ Space (Shift + Option + Space)"
        case .commandShiftSpace: return "⌘ ⇧ Space (Cmd + Shift + Space)"
        case .optionA: return "⌥ A (Option + A)"
        case .controlA: return "⌃ A (Control + A)"
        case .commandShiftA: return "⌘ ⇧ A (Cmd + Shift + A)"
        }
    }

    public var shortDisplay: String {
        switch self {
        case .optionSpace: return "⌥ Space"
        case .controlSpace: return "⌃ Space"
        case .shiftOptionSpace: return "⇧ ⌥ Space"
        case .commandShiftSpace: return "⌘ ⇧ Space"
        case .optionA: return "⌥ A"
        case .controlA: return "⌃ A"
        case .commandShiftA: return "⌘ ⇧ A"
        }
    }

    public var keyCode: UInt32 {
        switch self {
        case .optionSpace, .controlSpace, .shiftOptionSpace, .commandShiftSpace:
            return UInt32(kVK_Space)
        case .optionA, .controlA, .commandShiftA:
            return UInt32(kVK_ANSI_A)
        }
    }

    public var modifiers: UInt32 {
        switch self {
        case .optionSpace:
            return UInt32(optionKey)
        case .controlSpace:
            return UInt32(controlKey)
        case .shiftOptionSpace:
            return UInt32(shiftKey | optionKey)
        case .commandShiftSpace:
            return UInt32(cmdKey | shiftKey)
        case .optionA:
            return UInt32(optionKey)
        case .controlA:
            return UInt32(controlKey)
        case .commandShiftA:
            return UInt32(cmdKey | shiftKey)
        }
    }
}

/// Manages registration and handling of global keyboard shortcuts using Carbon Events.
@MainActor
public final class HotkeyManager: ObservableObject {
    public static let shared = HotkeyManager()

    public typealias HotkeyAction = @Sendable () -> Void
    private var onTrigger: HotkeyAction?
    private var onEscape: HotkeyAction?

    @Published public private(set) var currentOption: HotkeyOption = .optionSpace

    private var hotKeyRef: EventHotKeyRef?
    private var escapeHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var isHandlerInstalled: Bool = false
    private var isEscapeArmed: Bool = false

    public init() {}

    /// Registers the user's saved hotkey from UserDefaults, falling back to Option + Space.
    public func registerDefaultHotkey(action: @escaping HotkeyAction) {
        let savedRaw = UserDefaults.standard.string(forKey: "selectedHotkey") ?? HotkeyOption.optionSpace.rawValue
        let option = HotkeyOption(rawValue: savedRaw) ?? .optionSpace
        registerHotkey(option, action: action)
    }

    /// Registers a specific hotkey option and trigger action.
    public func registerHotkey(_ option: HotkeyOption, action: @escaping HotkeyAction) {
        self.onTrigger = action
        installCarbonHandlerIfNeeded()
        bindHotkey(option)
    }

    /// Dynamically switches the global shortcut at runtime and persists the selection.
    public func updateHotkey(_ option: HotkeyOption) {
        UserDefaults.standard.set(option.rawValue, forKey: "selectedHotkey")
        bindHotkey(option)
    }

    /// Dynamically arms the global Escape key (keyCode 53, 0 modifiers) to cancel/discard active listening or speaking.
    public func armEscapeHotkey(action: @escaping HotkeyAction) {
        self.onEscape = action
        guard !isEscapeArmed else { return }

        installCarbonHandlerIfNeeded()

        let escapeHotKeyID = EventHotKeyID(signature: OSType(0x45534350), id: 2) // 'ESCP'
        let status = RegisterEventHotKey(
            UInt32(kVK_Escape),
            0,
            escapeHotKeyID,
            GetApplicationEventTarget(),
            0,
            &escapeHotKeyRef
        )

        if status == noErr {
            isEscapeArmed = true
        } else {
            NSLog("Aura: Failed to register Escape EventHotKey (status: %d)", status)
        }
    }

    /// Disarms the global Escape key, immediately returning standard Escape key handling to macOS.
    public func disarmEscapeHotkey() {
        guard isEscapeArmed else { return }
        if let ref = escapeHotKeyRef {
            UnregisterEventHotKey(ref)
            self.escapeHotKeyRef = nil
        }
        isEscapeArmed = false
        self.onEscape = nil
    }

    private func bindHotkey(_ option: HotkeyOption) {
        if let existing = hotKeyRef {
            UnregisterEventHotKey(existing)
            hotKeyRef = nil
        }

        self.currentOption = option
        AppState.shared.hotkeyDisplayString = option.shortDisplay

        let hotKeyID = EventHotKeyID(signature: OSType(0x41555241), id: 1) // 'AURA'

        let status = RegisterEventHotKey(
            option.keyCode,
            option.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            NSLog("Aura: Failed to register Carbon EventHotKey '%@' (status: %d)", option.rawValue, status)
        }
    }

    private func installCarbonHandlerIfNeeded() {
        guard !isHandlerInstalled else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData, let event else { return noErr }
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    if status == noErr && hotKeyID.id == 2 {
                        manager.handleEscapeKey()
                    } else {
                        manager.handleHotKey()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        isHandlerInstalled = true
    }

    private func handleHotKey() {
        onTrigger?()
    }

    private func handleEscapeKey() {
        onEscape?()
    }

    public func unregister() {
        disarmEscapeHotkey()
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
        isHandlerInstalled = false
    }
}
