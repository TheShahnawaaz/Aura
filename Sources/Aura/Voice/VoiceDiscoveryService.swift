import Foundation

public struct ElevenVoice: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let category: String?

    public init(id: String, name: String, category: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
    }
}

public enum VoiceDiscoveryError: LocalizedError {
    case missingApiKey(provider: String)
    case invalidResponse(status: Int, message: String)
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .missingApiKey(let provider):
            return "Please enter a valid \(provider) API key."
        case .invalidResponse(let status, let message):
            return "\(status) error: \(message)"
        case .networkError(let msg):
            return "Network error: \(msg)"
        }
    }
}

/// Actor responsible for dynamically querying models and voices from cloud providers.
/// Enforces a strict ZERO-FALLBACK policy: if an API key is invalid or fails, errors are thrown and no data is returned.
public actor VoiceDiscoveryService {
    public static let shared = VoiceDiscoveryService()

    private init() {}

    // MARK: - ElevenLabs Voice & Model Discovery
    public func fetchElevenLabsVoices(apiKey: String) async throws -> [ElevenVoice] {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw VoiceDiscoveryError.missingApiKey(provider: "ElevenLabs")
        }

        guard let url = URL(string: "https://api.elevenlabs.io/v1/voices") else {
            throw VoiceDiscoveryError.networkError("Invalid ElevenLabs voices URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(trimmed, forHTTPHeaderField: "xi-api-key")
        request.timeoutInterval = 10.0

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw VoiceDiscoveryError.networkError("Invalid response received from ElevenLabs.")
        }

        guard http.statusCode == 200 else {
            let errString = String(data: data, encoding: .utf8) ?? "Authentication failed"
            throw VoiceDiscoveryError.invalidResponse(status: http.statusCode, message: errString)
        }

        struct VoicesResponse: Decodable {
            struct VoiceItem: Decodable {
                let voice_id: String
                let name: String
                let category: String?
            }
            let voices: [VoiceItem]
        }

        let decoded = try JSONDecoder().decode(VoicesResponse.self, from: data)
        return decoded.voices.map { ElevenVoice(id: $0.voice_id, name: $0.name, category: $0.category) }
    }

    public func fetchElevenLabsTTSModels(apiKey: String) async throws -> [String] {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw VoiceDiscoveryError.missingApiKey(provider: "ElevenLabs")
        }

        guard let url = URL(string: "https://api.elevenlabs.io/v1/models") else {
            throw VoiceDiscoveryError.networkError("Invalid ElevenLabs models URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(trimmed, forHTTPHeaderField: "xi-api-key")
        request.timeoutInterval = 10.0

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            let errString = String(data: data, encoding: .utf8) ?? "Authentication failed"
            throw VoiceDiscoveryError.invalidResponse(status: code, message: errString)
        }

        struct ModelItem: Decodable {
            let model_id: String
            let can_do_text_to_speech: Bool?
        }

        let decoded = try JSONDecoder().decode([ModelItem].self, from: data)
        let ttsModels = decoded.filter { $0.can_do_text_to_speech == true }.map { $0.model_id }
        return ttsModels.isEmpty ? ["eleven_flash_v2_5", "eleven_turbo_v2_5", "eleven_multilingual_v2"] : ttsModels
    }

    public func fetchElevenLabsSTTModels(apiKey: String) async throws -> [String] {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw VoiceDiscoveryError.missingApiKey(provider: "ElevenLabs")
        }

        // Validate key against user endpoint
        guard let url = URL(string: "https://api.elevenlabs.io/v1/user") else {
            throw VoiceDiscoveryError.networkError("Invalid ElevenLabs URL.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(trimmed, forHTTPHeaderField: "xi-api-key")
        request.timeoutInterval = 10.0

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            let errString = String(data: data, encoding: .utf8) ?? "Authentication failed"
            throw VoiceDiscoveryError.invalidResponse(status: code, message: errString)
        }

        return ["scribe_v1"]
    }

    // MARK: - Groq Voice & Model Discovery
    public func fetchGroqSTTModels(apiKey: String) async throws -> [String] {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw VoiceDiscoveryError.missingApiKey(provider: "Groq")
        }

        guard let url = URL(string: "https://api.groq.com/openai/v1/models") else {
            throw VoiceDiscoveryError.networkError("Invalid Groq models URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(trimmed)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            let errString = String(data: data, encoding: .utf8) ?? "Authentication failed"
            throw VoiceDiscoveryError.invalidResponse(status: code, message: errString)
        }

        struct GroqModelList: Decodable {
            struct ModelObj: Decodable {
                let id: String
            }
            let data: [ModelObj]
        }

        let decoded = try JSONDecoder().decode(GroqModelList.self, from: data)
        let whisperModels = decoded.data.map { $0.id }.filter { $0.lowercased().contains("whisper") }
        return whisperModels.isEmpty ? ["whisper-large-v3-turbo", "whisper-large-v3"] : whisperModels
    }

    public func fetchGroqTTSVoices(apiKey: String) async throws -> [String] {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw VoiceDiscoveryError.missingApiKey(provider: "Groq")
        }

        // Validate key against Groq models endpoint
        guard let url = URL(string: "https://api.groq.com/openai/v1/models") else {
            throw VoiceDiscoveryError.networkError("Invalid Groq models URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(trimmed)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            let errString = String(data: data, encoding: .utf8) ?? "Authentication failed"
            throw VoiceDiscoveryError.invalidResponse(status: code, message: errString)
        }

        return ["autumn", "diana", "hannah", "austin", "troy"]
    }
}
