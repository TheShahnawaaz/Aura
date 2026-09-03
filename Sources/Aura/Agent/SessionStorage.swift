import Foundation

/// Manages disk persistence of multi-turn conversation sessions in Application Support.
public final class SessionStorage: @unchecked Sendable {
    public static let shared = SessionStorage()

    private let fileManager = FileManager.default
    private let storageDirectory: URL

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.storageDirectory = appSupport.appendingPathComponent("Aura/Chats", isDirectory: true)

        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    /// Loads all saved conversation sessions from disk sorted by updatedAt descending.
    public func loadAllSessions() -> [ConversationSession] {
        guard let files = try? fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        var sessions: [ConversationSession] = []
        let decoder = JSONDecoder()

        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let session = try? decoder.decode(ConversationSession.self, from: data) {
                sessions.append(session)
            }
        }

        return sessions.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Saves a conversation session to disk as a JSON file.
    public func saveSession(_ session: ConversationSession) {
        let fileUrl = storageDirectory.appendingPathComponent("\(session.id).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        if let data = try? encoder.encode(session) {
            try? data.write(to: fileUrl, options: .atomic)
        }
    }

    /// Deletes a conversation session from disk.
    public func deleteSession(id: String) {
        let fileUrl = storageDirectory.appendingPathComponent("\(id).json")
        try? fileManager.removeItem(at: fileUrl)
    }
}
