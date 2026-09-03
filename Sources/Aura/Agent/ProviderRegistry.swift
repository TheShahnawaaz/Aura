import Foundation

/// Defines the operational and network parameters for an LLM provider.
public struct ProviderConfig: Identifiable, Hashable, Sendable {
    public var id: String { providerId }
    public let providerId: String
    public let displayName: String
    public let defaultBaseURL: String
    public let envVarNames: [String]
    public let defaultModel: String
    public let apiKeyPlaceholder: String
    public let requiresApiKey: Bool
    public let helpURL: String?

    public init(
        providerId: String,
        displayName: String,
        defaultBaseURL: String,
        envVarNames: [String],
        defaultModel: String,
        apiKeyPlaceholder: String = "sk-...",
        requiresApiKey: Bool = true,
        helpURL: String? = nil
    ) {
        self.providerId = providerId
        self.displayName = displayName
        self.defaultBaseURL = defaultBaseURL
        self.envVarNames = envVarNames
        self.defaultModel = defaultModel
        self.apiKeyPlaceholder = apiKeyPlaceholder
        self.requiresApiKey = requiresApiKey
        self.helpURL = helpURL
    }
}

/// Central registry managing supported LLM providers, environment sniffing,
/// and API endpoint resolution.
public final class ProviderRegistry: Sendable {
    public static let shared = ProviderRegistry()

    public let providers: [ProviderConfig] = [
        ProviderConfig(
            providerId: "gemini",
            displayName: "Google Gemini",
            defaultBaseURL: "https://generativelanguage.googleapis.com/v1beta/openai",
            envVarNames: ["GEMINI_API_KEY", "GOOGLE_API_KEY", "LLM_API_KEY"],
            defaultModel: "gemini-2.5-flash",
            apiKeyPlaceholder: "AIzaSy...",
            requiresApiKey: true,
            helpURL: "https://aistudio.google.com/app/apikey"
        ),
        ProviderConfig(
            providerId: "openai",
            displayName: "OpenAI",
            defaultBaseURL: "https://api.openai.com/v1",
            envVarNames: ["OPENAI_API_KEY"],
            defaultModel: "gpt-4o-mini",
            apiKeyPlaceholder: "sk-proj-...",
            requiresApiKey: true,
            helpURL: "https://platform.openai.com/api-keys"
        ),
        ProviderConfig(
            providerId: "anthropic",
            displayName: "Anthropic Claude",
            defaultBaseURL: "https://api.anthropic.com/v1",
            envVarNames: ["ANTHROPIC_API_KEY"],
            defaultModel: "claude-3-5-sonnet-20241022",
            apiKeyPlaceholder: "sk-ant-...",
            requiresApiKey: true,
            helpURL: "https://console.anthropic.com/settings/keys"
        ),
        ProviderConfig(
            providerId: "groq",
            displayName: "Groq (Ultra-Fast)",
            defaultBaseURL: "https://api.groq.com/openai/v1",
            envVarNames: ["GROQ_API_KEY"],
            defaultModel: "llama-3.3-70b-versatile",
            apiKeyPlaceholder: "gsk_...",
            requiresApiKey: true,
            helpURL: "https://console.groq.com/keys"
        ),
        ProviderConfig(
            providerId: "deepseek",
            displayName: "DeepSeek",
            defaultBaseURL: "https://api.deepseek.com/v1",
            envVarNames: ["DEEPSEEK_API_KEY"],
            defaultModel: "deepseek-chat",
            apiKeyPlaceholder: "sk-...",
            requiresApiKey: true,
            helpURL: "https://platform.deepseek.com/api_keys"
        ),
        ProviderConfig(
            providerId: "mistral",
            displayName: "Mistral AI",
            defaultBaseURL: "https://api.mistral.ai/v1",
            envVarNames: ["MISTRAL_API_KEY"],
            defaultModel: "mistral-large-latest",
            apiKeyPlaceholder: "...",
            requiresApiKey: true,
            helpURL: "https://console.mistral.ai/api-keys"
        ),
        ProviderConfig(
            providerId: "ollama",
            displayName: "Ollama (Local)",
            defaultBaseURL: "http://localhost:11434/v1",
            envVarNames: ["OLLAMA_HOST"],
            defaultModel: "llama3.2",
            apiKeyPlaceholder: "Not required (Local)",
            requiresApiKey: false,
            helpURL: "https://ollama.com"
        ),
        ProviderConfig(
            providerId: "custom",
            displayName: "Custom / Proxy",
            defaultBaseURL: "http://localhost:8000/v1",
            envVarNames: ["AURA_BASE_URL", "OPENAI_BASE_URL", "LLM_BASE_URL"],
            defaultModel: "gpt-4o",
            apiKeyPlaceholder: "Optional",
            requiresApiKey: false,
            helpURL: nil
        )
    ]

    private init() {}

    /// Finds provider configuration by its ID or display name.
    public func find(idOrName: String) -> ProviderConfig {
        let lower = idOrName.lowercased()
        if let match = providers.first(where: { $0.providerId == lower || $0.displayName.lowercased() == lower }) {
            return match
        }
        return providers[0] // Default to Gemini
    }

    /// Sniffs the user's environment to automatically detect which provider key is available.
    public func autoDetectActiveEnvironment() -> (provider: ProviderConfig, apiKey: String, envVar: String)? {
        let env = ProcessInfo.processInfo.environment

        for provider in providers {
            for varName in provider.envVarNames {
                if let key = env[varName], !key.isEmpty {
                    return (provider, key, varName)
                }
            }
        }
        return nil
    }

    /// Resolves the storage key name for UserDefaults for a given provider.
    public func userDefaultsKeyForApiKey(providerId: String) -> String {
        switch providerId {
        case "gemini": return "googleApiKey"
        case "openai": return "openAiApiKey"
        case "anthropic": return "anthropicApiKey"
        case "groq": return "groqApiKey"
        case "deepseek": return "deepseekApiKey"
        case "mistral": return "mistralApiKey"
        default: return "\(providerId)ApiKey"
        }
    }
}
