import XCTest
@testable import Aura

final class EscapeCancelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MainActor.assumeIsolated {
            AppState.shared.resetToIdle()
        }
    }

    override func tearDown() {
        MainActor.assumeIsolated {
            AppState.shared.resetToIdle()
            HotkeyManager.shared.disarmEscapeHotkey()
        }
        super.tearDown()
    }

    func testCancelRecognitionOnNativeSpeechRecognizer() {
        let recognizer = NativeSpeechRecognizer.shared
        // Canceling when idle should be safe and idempotent
        recognizer.cancelRecognition()
        recognizer.stopRecognition()
    }

    @MainActor
    func testCancelOrDiscardWhenListening() {
        let appState = AppState.shared
        appState.startListening()
        appState.partialTranscript = "What is the weather"
        appState.transcript = "What is the weather"
        appState.audioLevel = 0.75

        XCTAssertTrue(appState.state.isListening)
        XCTAssertEqual(appState.partialTranscript, "What is the weather")

        // Simulate cancel/discard action triggered by Escape
        if let delegate = AppDelegate.shared {
            delegate.cancelOrDiscardActiveEvent()
        } else {
            AudioCaptureService.shared.stopCapture()
            NativeSpeechRecognizer.shared.cancelRecognition()
            SpeechSynthesizer.shared.stopSpeaking()
            AudioDuckingManager.shared.unduckMedia()
            appState.resetToIdle()
        }

        XCTAssertEqual(appState.state, .idle)
        XCTAssertEqual(appState.partialTranscript, "")
        XCTAssertEqual(appState.audioLevel, 0.0)
    }

    @MainActor
    func testCancelOrDiscardWhenSpeaking() {
        let appState = AppState.shared
        appState.state = .speaking(text: "I am reciting a long answer...")
        XCTAssertEqual(appState.state, .speaking(text: "I am reciting a long answer..."))

        // Simulate cancel/discard action triggered by Escape
        if let delegate = AppDelegate.shared {
            delegate.cancelOrDiscardActiveEvent()
        } else {
            SpeechSynthesizer.shared.stopSpeaking()
            AudioDuckingManager.shared.unduckMedia()
            appState.resetToIdle()
        }

        XCTAssertEqual(appState.state, .idle)
    }

    @MainActor
    func testCancelOrDiscardWhenTurnCompletedPresented() {
        let appState = AppState.shared
        appState.isTurnCompletedPresented = true

        if let delegate = AppDelegate.shared {
            delegate.cancelOrDiscardActiveEvent()
        } else {
            appState.dismissTurnCompleted()
        }

        XCTAssertFalse(appState.isTurnCompletedPresented)
        XCTAssertEqual(appState.state, .idle)
    }

    @MainActor
    func testHotkeyManagerArmAndDisarmEscape() {
        final class TriggerBox: @unchecked Sendable {
            var value = false
        }
        let box = TriggerBox()

        HotkeyManager.shared.armEscapeHotkey {
            box.value = true
        }

        // Arming a second time should be idempotent
        HotkeyManager.shared.armEscapeHotkey {
            box.value = true
        }

        HotkeyManager.shared.disarmEscapeHotkey()
        // Disarming a second time should be idempotent
        HotkeyManager.shared.disarmEscapeHotkey()

        XCTAssertFalse(box.value)
    }
}
