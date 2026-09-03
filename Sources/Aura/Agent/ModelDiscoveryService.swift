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

/// Service that dynamically queries provider APIs to discover available models,
/// filtering out non-conversational capabilities (e.g. text-to-speech, speech-to-text, embeddings).
public actor ModelDiscoveryService {
    public static let shared = ModelDiscoveryService()

    private var cache: [String: [DiscoveredModel]] = [:]
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8.0
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

    /// Fetches all text-generation & reasoning capable models for the given provider.
    public func fetchModels(
        provider: String,
        apiKey: String?,
        customBaseURL: String? = nil
    ) async -> [DiscoveredModel] {
        let config = ProviderRegistry.shared.find(idOrName: provider)
        let cacheKey = "\(config.providerId)_\(apiKey?.prefix(6) ?? "")"
        if let cached = cache[cacheKey], !cached.isEmpty {
            return cached
        }

        var discovered: [DiscoveredModel] = []

        switch config.providerId {
        case "gemini":
            discovered = await fetchGeminiModels(apiKey: apiKey)
        case "openai":
            discovered = await fetchOpenAICompatibleModels(
                baseURL: customBaseURL ?? config.defaultBaseURL,
                apiKey: apiKey,
                providerDisplayName: "OpenAI"
            )
        case "groq":
            discovered = await fetchOpenAICompatibleModels(
                baseURL: config.defaultBaseURL,
                apiKey: apiKey,
                providerDisplayName: "Groq"
            )
        case "deepseek":
            discovered = await fetchOpenAICompatibleModels(
                baseURL: config.defaultBaseURL,
                apiKey: apiKey,
                providerDisplayName: "DeepSeek"
            )
        case "mistral":
            discovered = await fetchOpenAICompatibleModels(
                baseURL: config.defaultBaseURL,
                apiKey: apiKey,
                providerDisplayName: "Mistral AI"
            )
        case "anthropic":
            discovered = await fetchAnthropicModels(apiKey: apiKey)
        case "ollama":
            discovered = await fetchOllamaModels(baseURL: customBaseURL)
        default:
            discovered = await fetchOpenAICompatibleModels(
                baseURL: customBaseURL ?? config.defaultBaseURL,
                apiKey: apiKey,
                providerDisplayName: config.displayName
            )
        }

        if discovered.isEmpty {
            discovered = fallbackModels(for: config.providerId)
        }

        cache[cacheKey] = discovered
        return discovered
    }

    // MARK: - Google Gemini API Discovery
    private func fetchGeminiModels(apiKey: String?) async -> [DiscoveredModel] {
        guard let key = apiKey, !key.isEmpty else {
            return fallbackModels(for: "gemini")
        }

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(key)") else {
            return fallbackModels(for: "gemini")
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return fallbackModels(for: "gemini")
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

            let decoded = try JSONDecoder().decode(GeminiListResponse.self, from: data)
            guard let rawModels = decoded.models else {
                return fallbackModels(for: "gemini")
            }

            var results: [DiscoveredModel] = []
            for m in rawModels {
                let id = m.name.replacingOccurrences(of: "models/", with: "")
                guard Self.isChatAndReasoningModel(modelId: id) else { continue }

                if let methods = m.supportedGenerationMethods, !methods.contains("generateContent") {
                    continue
                }

                let isRecommended = id.contains("gemini-2.5-flash") || id.contains("gemini-1.5-flash")
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
        } catch {
            return fallbackModels(for: "gemini")
        }
    }

    // MARK: - Generic OpenAI-Compatible Discovery (OpenAI, Groq, DeepSeek, Mistral, Custom)
    private func fetchOpenAICompatibleModels(
        baseURL: String,
        apiKey: String?,
        providerDisplayName: String
    ) async -> [DiscoveredModel] {
        let base = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/models") else {
            return fallbackModels(for: providerDisplayName)
        }

        var request = URLRequest(url: url)
        if let key = apiKey, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return fallbackModels(for: providerDisplayName)
            }

            struct OpenAIListResponse: Codable {
                struct OpenAIModelItem: Codable {
                    let id: String
                }
                let data: [OpenAIModelItem]?
            }

            let decoded = try JSONDecoder().decode(OpenAIListResponse.self, from: data)
            guard let rawModels = decoded.data else {
                return fallbackModels(for: providerDisplayName)
            }

            var results: [DiscoveredModel] = []
            for m in rawModels {
                let id = m.id
                guard Self.isChatAndReasoningModel(modelId: id) else { continue }

                let isRecommended = id.contains("gpt-4o-mini") ||
                                    id.contains("llama-3.3-70b") ||
                                    id.contains("deepseek-chat") ||
                                    id.contains("mistral-large")

                results.append(DiscoveredModel(
                    modelId: id,
                    displayName: isRecommended ? "\(id) (Recommended)" : id,
                    provider: providerDisplayName,
                    isRecommended: isRecommended
                ))
            }

            return results.sorted { ($0.isRecommended ? 0 : 1) < ($1.isRecommended ? 0 : 1) }
        } catch {
            return fallbackModels(for: providerDisplayName)
        }
    }

    // MARK: - Anthropic Claude Discovery
    private func fetchAnthropicModels(apiKey: String?) async -> [DiscoveredModel] {
        guard let key = apiKey, !key.isEmpty else {
            return fallbackModels(for: "anthropic")
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/models") else {
            return fallbackModels(for: "anthropic")
        }

        var request = URLRequest(url: url)
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return fallbackModels(for: "anthropic")
            }

            struct AnthropicListResponse: Codable {
                struct AnthropicModelItem: Codable {
                    let id: String
                    let display_name: String?
                }
                let data: [AnthropicModelItem]?
            }

            let decoded = try JSONDecoder().decode(AnthropicListResponse.self, from: data)
            guard let rawModels = decoded.data else {
                return fallbackModels(for: "anthropic")
            }

            var results: [DiscoveredModel] = []
            for m in rawModels {
                let id = m.id
                let isRecommended = id.contains("3-5-sonnet") || id.contains("3-7-sonnet")
                let display = m.display_name ?? id
                results.append(DiscoveredModel(
                    modelId: id,
                    displayName: isRecommended ? "\(display) (Recommended)" : display,
                    provider: "Anthropic Claude",
                    isRecommended: isRecommended
                ))
            }

            return results.sorted { ($0.isRecommended ? 0 : 1) < ($1.isRecommended ? 0 : 1) }
        } catch {
            return fallbackModels(for: "anthropic")
        }
    }

    // MARK: - Ollama Local Discovery
    private func fetchOllamaModels(baseURL: String?) async -> [DiscoveredModel] {
        let base = baseURL?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "http://localhost:11434"
        guard let url = URL(string: "\(base)/api/tags") else {
            return fallbackModels(for: "ollama")
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return fallbackModels(for: "ollama")
            }

            struct OllamaListResponse: Codable {
                struct OllamaModelItem: Codable {
                    let name: String
                }
                let models: [OllamaModelItem]?
            }

            let decoded = try JSONDecoder().decode(OllamaListResponse.self, from: data)
            guard let raw = decoded.models, !raw.isEmpty else {
                return fallbackModels(for: "ollama")
            }

            return raw.map {
                DiscoveredModel(
                    modelId: $0.name,
                    displayName: $0.name,
                    provider: "Ollama (Local)"
                )
            }
        } catch {
            return fallbackModels(for: "ollama")
        }
    }

    // MARK: - Fallback Presets
    public nonisolated func fallbackModels(for providerIdOrName: String) -> [DiscoveredModel] {
        let config = ProviderRegistry.shared.find(idOrName: providerIdOrName)

        switch config.providerId {
        case "gemini":
            return [
                DiscoveredModel(modelId: "gemini-2.5-flash", displayName: "Gemini 2.5 Flash (Recommended)", provider: "Google Gemini", isRecommended: true),
                DiscoveredModel(modelId: "gemini-2.5-flash-lite", displayName: "Gemini 2.5 Flash-Lite (Fast)", provider: "Google Gemini"),
                DiscoveredModel(modelId: "gemini-2.5-pro", displayName: "Gemini 2.5 Pro (Deep Reasoning)", provider: "Google Gemini"),
                DiscoveredModel(modelId: "gemini-1.5-flash", displayName: "Gemini 1.5 Flash", provider: "Google Gemini")
            ]
        case "openai":
            return [
                DiscoveredModel(modelId: "gpt-4o-mini", displayName: "GPT-4o Mini (Recommended)", provider: "OpenAI", isRecommended: true),
                DiscoveredModel(modelId: "gpt-4o", displayName: "GPT-4o (Flagship)", provider: "OpenAI"),
                DiscoveredModel(modelId: "o3-mini", displayName: "o3-mini (Reasoning)", provider: "OpenAI")
            ]
        case "groq":
            return [
                DiscoveredModel(modelId: "llama-3.3-70b-versatile", displayName: "Llama 3.3 70B (Recommended)", provider: "Groq", isRecommended: true),
                DiscoveredModel(modelId: "mixtral-8x7b-32768", displayName: "Mixtral 8x7B", provider: "Groq"),
                DiscoveredModel(modelId: "deepseek-r1-distill-llama-70b", displayName: "DeepSeek R1 Distill 70B", provider: "Groq")
            ]
        case "deepseek":
            return [
                DiscoveredModel(modelId: "deepseek-chat", displayName: "DeepSeek-V3 Chat (Recommended)", provider: "DeepSeek", isRecommended: true),
                DiscoveredModel(modelId: "deepseek-reasoner", displayName: "DeepSeek-R1 Reasoner", provider: "DeepSeek")
            ]
        case "mistral":
            return [
                DiscoveredModel(modelId: "mistral-large-latest", displayName: "Mistral Large (Recommended)", provider: "Mistral AI", isRecommended: true),
                DiscoveredModel(modelId: "codestral-latest", displayName: "Codestral (Code Specialist)", provider: "Mistral AI")
            ]
        case "anthropic":
            return [
                DiscoveredModel(modelId: "claude-3-5-sonnet-20241022", displayName: "Claude 3.5 Sonnet (Recommended)", provider: "Anthropic Claude", isRecommended: true),
                DiscoveredModel(modelId: "claude-3-5-haiku-20241022", displayName: "Claude 3.5 Haiku (Fast)", provider: "Anthropic Claude")
            ]
        default:
            return [
                DiscoveredModel(modelId: "llama3.2", displayName: "llama3.2 (Local)", provider: "Ollama (Local)"),
                DiscoveredModel(modelId: "mistral", displayName: "mistral (Local)", provider: "Ollama (Local)")
            ]
        }
    }
}
