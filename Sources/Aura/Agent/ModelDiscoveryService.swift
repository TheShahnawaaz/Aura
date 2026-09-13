import Foundation

/// Represents an AI model discovered dynamically from a provider's API.
public struct DiscoveredModel: Identifiable, Codable, Hashable, Sendable {
    public var id: String { modelId }
    public let modelId: String
    public let displayName: String
    public let provider: String
    public let contextWindow: Int?
    public let isRecommended: Bool

    public init(
        modelId: String,
        displayName: String,
        provider: String,
        contextWindow: Int? = nil,
        isRecommended: Bool = false
    ) {
        self.modelId = modelId
        self.displayName = displayName
        self.provider = provider
        self.contextWindow = contextWindow
        self.isRecommended = isRecommended
    }
}

public enum ModelDiscoveryError: LocalizedError {
    case missingApiKey(provider: String)
    case invalidEndpoint(String)
    case invalidResponse(status: Int, message: String)
    case networkError(String)
    case noModelsDiscovered(provider: String)

    public var errorDescription: String? {
        switch self {
        case .missingApiKey(let provider):
            return "Please enter a valid \(provider) API key."
        case .invalidEndpoint(let url):
            return "Invalid endpoint URL: \(url)"
        case .invalidResponse(status: let status, message: let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(status) error: \(trimmed.isEmpty ? "Request failed" : trimmed)"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .noModelsDiscovered(let provider):
            return "No conversational models found for \(provider)."
        }
    }
}

/// Actor responsible for dynamically querying models from cloud or local AI providers.
/// Enforces a strict ZERO-FALLBACK policy (matching VoiceDiscoveryService):
/// if an API key or endpoint fails, errors are thrown and NO fake models are returned.
public actor ModelDiscoveryService {
    public static let shared = ModelDiscoveryService()

    private var cache: [String: [DiscoveredModel]] = [:]
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        self.session = URLSession(configuration: config)
    }

    /// Evaluates whether a model identifier represents a conversational / reasoning model
    /// capable of executing user turns and tools, filtering out TTS, STT, and embeddings.
    public static func isChatAndReasoningModel(modelId: String) -> Bool {
        let lower = modelId.lowercased()
        if lower.contains("-tts") || lower.starts(with: "tts-") { return false }
        if lower.contains("whisper") || lower.contains("transcribe") { return false }
        if lower.contains("embedding") || lower.contains("embed") { return false }
        if lower.contains("dall-e") || lower.contains("imagen") { return false }
        if lower.contains("moderation") || lower.contains("reward") { return false }
        if lower.contains("realtime") { return false }
        if lower.contains("babbage") || lower.contains("davinci") { return false }
        return true
    }

    /// Clears the discovery cache.
    public func clearCache() {
        cache.removeAll()
    }

    /// Dynamically fetches all text-generation & reasoning models for the given provider.
    /// Strictly throws on errors with zero hardcoded fallbacks.
    public func fetchModels(
        provider: String,
        apiKey: String?,
        customBaseURL: String? = nil,
        forceRefresh: Bool = false
    ) async throws -> [DiscoveredModel] {
        let config = ProviderRegistry.shared.find(idOrName: provider)
        let trimmedKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedURL = customBaseURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cacheKey = "\(config.providerId)_\(trimmedURL)_\(trimmedKey.prefix(8))"

        if !forceRefresh, let cached = cache[cacheKey], !cached.isEmpty {
            return cached
        }

        var discovered: [DiscoveredModel] = []

        switch config.providerId {
        case "gemini":
            discovered = try await fetchGeminiModels(apiKey: trimmedKey)
        case "openai":
            discovered = try await fetchOpenAICompatibleModels(
                baseURL: !trimmedURL.isEmpty ? trimmedURL : config.defaultBaseURL,
                apiKey: trimmedKey,
                providerDisplayName: "OpenAI",
                requireKey: true
            )
        case "groq":
            discovered = try await fetchOpenAICompatibleModels(
                baseURL: config.defaultBaseURL,
                apiKey: trimmedKey,
                providerDisplayName: "Groq",
                requireKey: true
            )
        case "deepseek":
            discovered = try await fetchOpenAICompatibleModels(
                baseURL: config.defaultBaseURL,
                apiKey: trimmedKey,
                providerDisplayName: "DeepSeek",
                requireKey: true
            )
        case "mistral":
            discovered = try await fetchOpenAICompatibleModels(
                baseURL: config.defaultBaseURL,
                apiKey: trimmedKey,
                providerDisplayName: "Mistral AI",
                requireKey: true
            )
        case "anthropic":
            discovered = try await fetchAnthropicModels(apiKey: trimmedKey)
        case "ollama":
            discovered = try await fetchOllamaModels(baseURL: !trimmedURL.isEmpty ? trimmedURL : config.defaultBaseURL)
        case "custom":
            let effectiveURL = !trimmedURL.isEmpty ? trimmedURL : config.defaultBaseURL
            discovered = try await fetchOpenAICompatibleModels(
                baseURL: effectiveURL,
                apiKey: trimmedKey,
                providerDisplayName: "Custom / OpenAI-Compatible",
                requireKey: false
            )
        default:
            let effectiveURL = !trimmedURL.isEmpty ? trimmedURL : config.defaultBaseURL
            discovered = try await fetchOpenAICompatibleModels(
                baseURL: effectiveURL,
                apiKey: trimmedKey,
                providerDisplayName: config.displayName,
                requireKey: config.requiresApiKey
            )
        }

        guard !discovered.isEmpty else {
            throw ModelDiscoveryError.noModelsDiscovered(provider: config.displayName)
        }

        cache[cacheKey] = discovered
        return discovered
    }

    // MARK: - Google Gemini API Discovery
    private func fetchGeminiModels(apiKey: String) async throws -> [DiscoveredModel] {
        guard !apiKey.isEmpty else {
            throw ModelDiscoveryError.missingApiKey(provider: "Google Gemini")
        }

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)") else {
            throw ModelDiscoveryError.invalidEndpoint("Google Gemini API")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw ModelDiscoveryError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ModelDiscoveryError.networkError("Invalid response from Google Gemini.")
        }

        guard http.statusCode == 200 else {
            let errString = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw ModelDiscoveryError.invalidResponse(status: http.statusCode, message: errString)
        }

        struct GeminiListResponse: Codable {
            struct GeminiModelItem: Codable {
                let name: String
                let displayName: String?
                let supportedGenerationMethods: [String]?
                let inputTokenLimit: Int?
            }
            let models: [GeminiModelItem]?
        }

        let decoded: GeminiListResponse
        do {
            decoded = try JSONDecoder().decode(GeminiListResponse.self, from: data)
        } catch {
            throw ModelDiscoveryError.invalidResponse(status: 200, message: "Failed to parse Gemini model response.")
        }

        guard let rawModels = decoded.models else {
            return []
        }

        var results: [DiscoveredModel] = []
        for m in rawModels {
            let id = m.name.replacingOccurrences(of: "models/", with: "")
            guard Self.isChatAndReasoningModel(modelId: id) else { continue }

            if let methods = m.supportedGenerationMethods, !methods.contains("generateContent") {
                continue
            }

            let isRecommended = id.contains("flash")
            let display = m.displayName ?? id

            results.append(DiscoveredModel(
                modelId: id,
                displayName: isRecommended ? "\(display) (Recommended)" : display,
                provider: "Google Gemini",
                contextWindow: m.inputTokenLimit,
                isRecommended: isRecommended
            ))
        }

        return results.sorted { ($0.isRecommended ? 0 : 1) < ($1.isRecommended ? 0 : 1) }
    }

    // MARK: - Generic OpenAI-Compatible Discovery (OpenAI, Groq, DeepSeek, Mistral, Custom / Proxy)
    private func fetchOpenAICompatibleModels(
        baseURL: String,
        apiKey: String,
        providerDisplayName: String,
        requireKey: Bool
    ) async throws -> [DiscoveredModel] {
        if requireKey && apiKey.isEmpty {
            throw ModelDiscoveryError.missingApiKey(provider: providerDisplayName)
        }

        let trimmedBase = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpointStr = trimmedBase.hasSuffix("/models") ? trimmedBase : "\(trimmedBase)/models"

        guard let url = URL(string: endpointStr) else {
            throw ModelDiscoveryError.invalidEndpoint(endpointStr)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ModelDiscoveryError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ModelDiscoveryError.networkError("Invalid response from server.")
        }

        guard (200...299).contains(http.statusCode) else {
            let errString = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw ModelDiscoveryError.invalidResponse(status: http.statusCode, message: errString)
        }

        struct OpenAIListResponse: Codable {
            struct OpenAIModelItem: Codable {
                let id: String
            }
            let data: [OpenAIModelItem]?
        }

        let decoded: OpenAIListResponse
        do {
            decoded = try JSONDecoder().decode(OpenAIListResponse.self, from: data)
        } catch {
            throw ModelDiscoveryError.invalidResponse(status: http.statusCode, message: "Unexpected model response schema.")
        }

        guard let rawModels = decoded.data else {
            return []
        }

        var results: [DiscoveredModel] = []
        for m in rawModels {
            let id = m.id
            guard Self.isChatAndReasoningModel(modelId: id) else { continue }

            let isRecommended = id.contains("flash") ||
                                id.contains("gpt-4o-mini") ||
                                id.contains("llama-3.3-70b") ||
                                id.contains("deepseek-chat") ||
                                id.contains("sonnet")

            results.append(DiscoveredModel(
                modelId: id,
                displayName: isRecommended ? "\(id) (Recommended)" : id,
                provider: providerDisplayName,
                isRecommended: isRecommended
            ))
        }

        return results.sorted { ($0.isRecommended ? 0 : 1) < ($1.isRecommended ? 0 : 1) }
    }

    // MARK: - Anthropic Claude Discovery
    private func fetchAnthropicModels(apiKey: String) async throws -> [DiscoveredModel] {
        guard !apiKey.isEmpty else {
            throw ModelDiscoveryError.missingApiKey(provider: "Anthropic Claude")
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/models") else {
            throw ModelDiscoveryError.invalidEndpoint("Anthropic API")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ModelDiscoveryError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ModelDiscoveryError.networkError("Invalid response from Anthropic.")
        }

        guard (200...299).contains(http.statusCode) else {
            let errString = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw ModelDiscoveryError.invalidResponse(status: http.statusCode, message: errString)
        }

        struct AnthropicListResponse: Codable {
            struct AnthropicModelItem: Codable {
                let id: String
                let display_name: String?
            }
            let data: [AnthropicModelItem]?
        }

        let decoded: AnthropicListResponse
        do {
            decoded = try JSONDecoder().decode(AnthropicListResponse.self, from: data)
        } catch {
            throw ModelDiscoveryError.invalidResponse(status: http.statusCode, message: "Failed to parse Claude model response.")
        }

        guard let rawModels = decoded.data else {
            return []
        }

        var results: [DiscoveredModel] = []
        for m in rawModels {
            let id = m.id
            let isRecommended = id.contains("sonnet")
            let display = m.display_name ?? id
            results.append(DiscoveredModel(
                modelId: id,
                displayName: isRecommended ? "\(display) (Recommended)" : display,
                provider: "Anthropic Claude",
                isRecommended: isRecommended
            ))
        }

        return results.sorted { ($0.isRecommended ? 0 : 1) < ($1.isRecommended ? 0 : 1) }
    }

    // MARK: - Ollama Local Discovery
    private func fetchOllamaModels(baseURL: String?) async throws -> [DiscoveredModel] {
        let base = baseURL?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "http://localhost:11434"
        guard let url = URL(string: "\(base)/api/tags") else {
            throw ModelDiscoveryError.invalidEndpoint(base)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw ModelDiscoveryError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ModelDiscoveryError.networkError("Invalid response from Ollama.")
        }

        guard (200...299).contains(http.statusCode) else {
            let errString = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw ModelDiscoveryError.invalidResponse(status: http.statusCode, message: errString)
        }

        struct OllamaListResponse: Codable {
            struct OllamaModelItem: Codable {
                let name: String
            }
            let models: [OllamaModelItem]?
        }

        let decoded: OllamaListResponse
        do {
            decoded = try JSONDecoder().decode(OllamaListResponse.self, from: data)
        } catch {
            throw ModelDiscoveryError.invalidResponse(status: http.statusCode, message: "Failed to parse Ollama model response.")
        }

        guard let raw = decoded.models, !raw.isEmpty else {
            return []
        }

        return raw.map {
            DiscoveredModel(
                modelId: $0.name,
                displayName: $0.name,
                provider: "Ollama (Local)"
            )
        }
    }
}
