import AppKit
import Foundation

/// Manages media playback pausing and ducking when Aura is actively listening or speaking.
/// Checks running process bundle IDs first to avoid triggering macOS "Choose Application" dialogs.
public final class AudioDuckingManager: @unchecked Sendable {
    public static let shared = AudioDuckingManager()

    private var wasMusicPlaying: Bool = false
    private var wasSpotifyPlaying: Bool = false

    private let spotifyBundleId = "com.spotify.client"
    private let musicBundleId = "com.apple.Music"

    private init() {}

    /// Pauses currently playing media apps (Music, Spotify) before listening or speaking.
    public func duckMedia() {
        Task.detached(priority: .userInitiated) {
            self.pauseAppleMusic()
            self.pauseSpotify()
        }
    }

    /// Resumes previously playing media after assistant finishes speaking.
    public func unduckMedia() {
        Task.detached(priority: .utility) {
            if self.wasMusicPlaying {
                self.resumeAppleMusic()
                self.wasMusicPlaying = false
            }
            if self.wasSpotifyPlaying {
                self.resumeSpotify()
                self.wasSpotifyPlaying = false
            }
        }
    }

    private func isRunning(bundleId: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).isEmpty
    }

    private func pauseAppleMusic() {
        let shouldDuck = UserDefaults.standard.object(forKey: "pauseMusicOnListen") != nil ? UserDefaults.standard.bool(forKey: "pauseMusicOnListen") : true
        guard shouldDuck, isRunning(bundleId: musicBundleId) else { return }

        let script = """
        tell application "Music"
            if player state is playing then
                pause
                return true
            end if
        end tell
        return false
        """
        if let result = executeAppleScript(script), result == "true" {
            wasMusicPlaying = true
        }
    }

    private func resumeAppleMusic() {
        guard isRunning(bundleId: musicBundleId) else { return }

        let script = """
        tell application "Music" to play
        """
        _ = executeAppleScript(script)
    }

    private func pauseSpotify() {
        let shouldDuck = UserDefaults.standard.object(forKey: "pauseSpotifyOnListen") != nil ? UserDefaults.standard.bool(forKey: "pauseSpotifyOnListen") : true
        guard shouldDuck, isRunning(bundleId: spotifyBundleId) else { return }

        let script = """
        tell application "Spotify"
            if player state is playing then
                pause
                return true
            end if
        end tell
        return false
        """
        if let result = executeAppleScript(script), result == "true" {
            wasSpotifyPlaying = true
        }
    }

    private func resumeSpotify() {
        guard isRunning(bundleId: spotifyBundleId) else { return }

        let script = """
        tell application "Spotify" to play
        """
        _ = executeAppleScript(script)
    }

    private func executeAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: source) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil {
                return output.stringValue
            }
        }
        return nil
    }
}
