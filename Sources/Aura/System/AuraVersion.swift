import Foundation

/// Single source of truth for version and distribution metadata in Aura.
public enum AuraVersion {
    /// Current semantic version string (e.g. "1.0.0").
    public static let current = "1.1.0"

    /// Internal build number string (e.g. "1").
    public static let build = "2"

    /// Release date string for this build.
    public static let releaseDate = "2026-09-21"

    /// Public GitHub repository identifier.
    public static let repository = "TheShahnawaaz/Aura"

    /// GitHub Releases latest API endpoint.
    public static var releasesApiURL: URL {
        URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
    }

    /// Direct DMG download URL for latest release.
    public static var latestDmgDownloadURL: URL {
        URL(string: "https://github.com/\(repository)/releases/latest/download/Aura.dmg")!
    }

    /// GitHub Releases page for manual browsing.
    public static var releasesWebURL: URL {
        URL(string: "https://github.com/\(repository)/releases")!
    }

    /// Formatted display string, e.g. "v1.1.0 (Build 2)".
    public static var displayString: String {
        "v\(current) (Build \(build))"
    }
}
