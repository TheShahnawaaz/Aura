import Foundation
import AppKit

/// Service responsible for querying GitHub Releases to discover updates,
/// compare semantic versions, and facilitate direct DMG downloads.
@MainActor
public final class UpdateService: ObservableObject {
    public static let shared = UpdateService()

    @Published public var isChecking: Bool = false
    @Published public var isUpdateAvailable: Bool = false
    @Published public var latestVersion: String? = nil
    @Published public var releaseNotes: String? = nil
    @Published public var downloadURL: URL? = nil
    @Published public var errorMessage: String? = nil
    @Published public var lastCheckDate: Date? = nil

    private struct GitHubRelease: Decodable {
        let tag_name: String
        let name: String?
        let body: String?
        let html_url: String
        let assets: [GitHubAsset]?
    }

    private struct GitHubAsset: Decodable {
        let name: String
        let browser_download_url: String
    }

    private init() {}

    /// Checks GitHub Releases API for updates.
    /// - Parameter userInitiated: If true, will present user-facing alerts when up-to-date or on error.
    public func checkForUpdates(userInitiated: Bool = true) {
        guard !isChecking else { return }
        isChecking = true
        errorMessage = nil

        Task {
            do {
                var request = URLRequest(url: AuraVersion.releasesApiURL)
                request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
                request.setValue("Aura-macOS/\(AuraVersion.current)", forHTTPHeaderField: "User-Agent")
                request.timeoutInterval = 15

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                if httpResponse.statusCode == 404 {
                    // No releases published yet on GitHub
                    self.isChecking = false
                    self.isUpdateAvailable = false
                    self.lastCheckDate = Date()
                    if userInitiated {
                        self.presentAlert(
                            title: "You're on the latest build",
                            message: "Aura \(AuraVersion.displayString) is currently up to date."
                        )
                    }
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let remoteTag = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))

                let isNewer = self.isVersion(remoteTag, newerThan: AuraVersion.current)
                self.latestVersion = remoteTag
                self.releaseNotes = release.body
                self.lastCheckDate = Date()

                // Find Aura.dmg in assets if available
                if let dmgAsset = release.assets?.first(where: { $0.name.hasSuffix(".dmg") }),
                   let assetURL = URL(string: dmgAsset.browser_download_url) {
                    self.downloadURL = assetURL
                } else {
                    self.downloadURL = URL(string: release.html_url)
                }

                self.isUpdateAvailable = isNewer
                self.isChecking = false

                if userInitiated {
                    if isNewer {
                        self.presentUpdateAvailableAlert(version: remoteTag, notes: release.body)
                    } else {
                        self.presentAlert(
                            title: "You're Up to Date!",
                            message: "Aura \(AuraVersion.displayString) is currently the newest version available."
                        )
                    }
                }
            } catch {
                self.isChecking = false
                self.errorMessage = error.localizedDescription
                if userInitiated {
                    self.presentAlert(
                        title: "Update Check Failed",
                        message: "Could not check for updates at this time. Please ensure you have an active internet connection."
                    )
                }
            }
        }
    }

    /// Opens the latest DMG download URL or release page in user's default browser.
    public func openDownloadPage() {
        let targetURL = downloadURL ?? AuraVersion.latestDmgDownloadURL
        NSWorkspace.shared.open(targetURL)
    }

    /// Helper comparing semantic version strings (e.g. "1.1.0" > "1.0.0").
    private func isVersion(_ remote: String, newerThan current: String) -> Bool {
        let remoteParts = remote.split(separator: "-")[0].split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: "-")[0].split(separator: ".").compactMap { Int($0) }

        let count = max(remoteParts.count, currentParts.count)
        for i in 0..<count {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if r > c { return true }
            if r < c { return false }
        }
        return false
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func presentUpdateAvailableAlert(version: String, notes: String?) {
        let alert = NSAlert()
        alert.messageText = "New Update Available: Aura v\(version)"
        let previewNotes = notes?.prefix(300) ?? "A new version of Aura is available for download."
        alert.informativeText = "\(previewNotes)\n\nWould you like to download the update now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download Update")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            self.openDownloadPage()
        }
    }
}
