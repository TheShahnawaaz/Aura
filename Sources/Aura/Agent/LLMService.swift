import Foundation

/// Service for generating intelligent natural language responses using cloud or local LLMs.
public final class LLMService: @unchecked Sendable {
    public static let shared = LLMService()

    private let session: URLSession

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12.0
        config.timeoutIntervalForResource = 15.0
        self.session = URLSession(configuration: config)
    }

    // MARK: - Metadata & Diagnostics
    public var activeModelName: String {
        resolveModel()
    }

    public var activeProviderName: String {
        let providerName = UserDefaults.standard.string(forKey: "selectedProvider") ?? activeProviderDefault()
        let config = ProviderRegistry.shared.find(idOrName: providerName)
        if config.providerId == "custom" {
            let url = resolveBaseURL()
            if url.contains("localhost") || url.contains("127.0.0.1") {
                return "Local Endpoint"
            }
            return "Custom OpenAI"
        }
        return config.displayName
    }

    public var credentialSource: String {
        let providerName = UserDefaults.standard.string(forKey: "selectedProvider") ?? activeProviderDefault()
        let config = ProviderRegistry.shared.find(idOrName: providerName)
        let storageKey = ProviderRegistry.shared.userDefaultsKeyForApiKey(providerId: config.providerId)

        if let key = UserDefaults.standard.string(forKey: storageKey), !key.isEmpty {
            return "Settings (\(config.displayName))"
        }

        let env = ProcessInfo.processInfo.environment
        for varName in config.envVarNames {
            if env[varName] != nil {
                return "Environment (\(varName))"
            }
        }

        if !config.requiresApiKey {
            return "No Key Required"
        }

        return "Not Configured"
    }

    public var activeBaseURL: String {
        resolveBaseURL()
    }

    /// Tests the connection to the configured model and returns the latency in milliseconds.
    public func pingModel() async -> (success: Bool, latencyMs: Int, response: String, error: String?) {
        guard let apiKey = resolveApiKey(), !apiKey.isEmpty else {
            return (false, 0, "", "No API key configured")
        }

        let baseURL = resolveBaseURL()
        let model = resolveModel()
        guard !model.isEmpty else {
            return (false, 0, "", "No model selected. Please fetch models first.")
        }
        let endpoint = baseURL.hasSuffix("/") ? "\(baseURL)chat/completions" : "\(baseURL)/chat/completions"

        guard let url = URL(string: endpoint) else {
            return (false, 0, "", "Invalid endpoint URL")
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if apiKey != "local-no-key" {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": "Respond with the single word: Pong"]
            ],
            "max_tokens": 10,
            "temperature": 0.1
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)
            let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

            guard let http = response as? HTTPURLResponse else {
                return (false, elapsedMs, "", "Invalid response from server")
            }

            guard (200...299).contains(http.statusCode) else {
                let errStr = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                return (false, elapsedMs, "", "Server error: \(errStr)")
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let text = message["content"] as? String {
                let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                return (true, elapsedMs, cleaned.isEmpty ? "Connected" : cleaned, nil)
            }

            return (true, elapsedMs, "Connected", nil)
        } catch {
            let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
            return (false, elapsedMs, "", error.localizedDescription)
        }
    }

    /// Generates a spoken response for the user's natural language voice query.
    public func generateResponse(prompt: String) async -> String {
        // 1. Check for quick local system queries first (instant response)
        if let localAnswer = handleQuickSystemQuery(prompt: prompt) {
            return localAnswer
        }

        // 2. Resolve LLM configuration from UserDefaults or environment variables
        let apiKey = resolveApiKey()
        guard let apiKey, !apiKey.isEmpty else {
            return "I heard: \"\(prompt)\". To enable full conversational intelligence, please enter an API key in Aura's Settings."
        }

        let baseURL = resolveBaseURL()
        let model = resolveModel()

        // 3. Make OpenAI-compatible chat completion request
        do {
            let endpoint = baseURL.hasSuffix("/") ? "\(baseURL)chat/completions" : "\(baseURL)/chat/completions"
            guard let url = URL(string: endpoint) else {
                return "Understood: \"\(prompt)\"."
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            if apiKey != "local-no-key" {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let temp = UserDefaults.standard.object(forKey: "llmTemperature") != nil ? UserDefaults.standard.double(forKey: "llmTemperature") : 0.2
            let maxTok = UserDefaults.standard.integer(forKey: "llmMaxTokens") > 0 ? UserDefaults.standard.integer(forKey: "llmMaxTokens") : 150

            let body: [String: Any] = [
                "model": model,
                "messages": [
                    [
                        "role": "system",
                        "content": "You are Aura, a smart macOS voice assistant. Provide a concise, direct, natural spoken answer in 1 to 2 sentences. Never use markdown formatting, asterisks, or bullet points."
                    ],
                    [
                        "role": "user",
                        "content": prompt
                    ]
                ],
                "max_tokens": maxTok,
                "temperature": temp
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                NSLog("Aura LLM error: HTTP %ld", (response as? HTTPURLResponse)?.statusCode ?? 0)
                return "I heard: \"\(prompt)\". I had trouble reaching the AI service."
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
                return cleaned.isEmpty ? "Understood." : cleaned
            }
        } catch {
            NSLog("Aura LLM failure: %@", error.localizedDescription)
        }

        return "I heard: \"\(prompt)\"."
    }

    /// Executes a multi-turn chat completion with optional tool definitions, parsing both message content and tool calls.
    public func chatCompletion(
        messages: [[String: Any]],
        tools: [[String: Any]]? = nil
    ) async throws -> (content: String?, toolCalls: [RawToolCall]?) {
        guard let apiKey = resolveApiKey(), !apiKey.isEmpty else {
            throw NSError(domain: "AuraLLM", code: 401, userInfo: [NSLocalizedDescriptionKey: "No API key configured in Aura Settings."])
        }

        let baseURL = resolveBaseURL()
        let model = resolveModel()
        guard !model.isEmpty else {
            throw NSError(domain: "AuraLLM", code: 400, userInfo: [NSLocalizedDescriptionKey: "No model selected. Please select a model in Aura Settings."])
        }
        let endpoint = baseURL.hasSuffix("/") ? "\(baseURL)chat/completions" : "\(baseURL)/chat/completions"

        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "AuraLLM", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint URL."])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if apiKey != "local-no-key" {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let temp = UserDefaults.standard.object(forKey: "llmTemperature") != nil ? UserDefaults.standard.double(forKey: "llmTemperature") : 0.2
        let maxTok = UserDefaults.standard.integer(forKey: "llmMaxTokens") > 0 ? UserDefaults.standard.integer(forKey: "llmMaxTokens") : 600

        var body: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": maxTok,
            "temperature": temp
        ]

        if let tools, !tools.isEmpty {
            body["tools"] = tools
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "AuraLLM", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response."])
        }

        guard (200...299).contains(http.statusCode) else {
            let errStr = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "AuraLLM", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errStr])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any] else {
            return (nil, nil)
        }

        let content = message["content"] as? String

        var parsedToolCalls: [RawToolCall]? = nil
        if let rawCalls = message["tool_calls"] as? [[String: Any]] {
            parsedToolCalls = rawCalls.compactMap { callDict in
                guard let function = callDict["function"] as? [String: Any],
                      let name = function["name"] as? String else {
                    return nil
                }
                let id = callDict["id"] as? String ?? UUID().uuidString
                let args: String
                if let argsStr = function["arguments"] as? String {
                    args = argsStr
                } else if let argsDict = function["arguments"] as? [String: Any],
                          let argsData = try? JSONSerialization.data(withJSONObject: argsDict),
                          let jsonStr = String(data: argsData, encoding: .utf8) {
                    args = jsonStr
                } else {
                    args = "{}"
                }
                return RawToolCall(id: id, name: name, arguments: args)
            }
        }

        return (content, parsedToolCalls)
    }

    /// Auto-generates a concise 3-4 word title for a new conversation thread.
    public func generateTitle(for prompt: String) async -> String {
        do {
            let msgs: [[String: Any]] = [
                [
                    "role": "system",
                    "content": "You generate a concise 3 to 4 word title for a conversation. Output ONLY the title with no quotes, no markdown, and no trailing punctuation."
                ],
                [
                    "role": "user",
                    "content": "User said: \"\(prompt)\""
                ]
            ]
            let res = try await chatCompletion(messages: msgs, tools: nil)
            if let title = res.content?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)),
               !title.isEmpty && title.count < 40 {
                return title
            }
        } catch {}
        return "New Conversation"
    }

    public func activeProviderDefault() -> String {
        if let auto = ProviderRegistry.shared.autoDetectActiveEnvironment() {
            return auto.provider.displayName
        }
        return "Google Gemini"
    }

    public func resolveApiKey() -> String? {
        let providerName = UserDefaults.standard.string(forKey: "selectedProvider") ?? activeProviderDefault()
        let config = ProviderRegistry.shared.find(idOrName: providerName)
        let storageKey = ProviderRegistry.shared.userDefaultsKeyForApiKey(providerId: config.providerId)

        // Priority 1: User explicitly configured key for this provider
        if let key = UserDefaults.standard.string(forKey: storageKey), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return key.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Priority 2: Provider specific environment variables ONLY
        let env = ProcessInfo.processInfo.environment
        for varName in config.envVarNames {
            if let key = env[varName], !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return key.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Providers that don't strictly require an API key (e.g. unauthenticated local engines)
        if !config.requiresApiKey {
            return "local-no-key"
        }

        return nil
    }

    public func resolveBaseURL() -> String {
        let providerName = UserDefaults.standard.string(forKey: "selectedProvider") ?? activeProviderDefault()
        let config = ProviderRegistry.shared.find(idOrName: providerName)

        if config.providerId == "custom" || config.providerId == "ollama" {
            if let custom = UserDefaults.standard.string(forKey: "customBaseUrl"), !custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let trimmed = custom.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
            }
        }

        let env = ProcessInfo.processInfo.environment
        if let base = env["OPENAI_BASE_URL"] ?? env["LLM_BASE_URL"] ?? env["AURA_BASE_URL"], !base.isEmpty {
            let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
        }

        return config.defaultBaseURL
    }

    public func resolveModel() -> String {
        if let saved = UserDefaults.standard.string(forKey: "selectedModel"), !saved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return saved.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let providerName = UserDefaults.standard.string(forKey: "selectedProvider") ?? activeProviderDefault()
        let config = ProviderRegistry.shared.find(idOrName: providerName)

        let env = ProcessInfo.processInfo.environment
        if config.providerId == "gemini", let model = env["GEMINI_MODEL"] ?? env["LLM_MODEL"], !model.isEmpty {
            return model
        }
        if config.providerId == "openai", let model = env["OPENAI_MODEL"], !model.isEmpty {
            return model
        }
        if let model = env["AURA_MODEL"], !model.isEmpty {
            return model
        }

        return config.defaultModel
    }

    public func isModelCompatibleWithProvider(model: String, providerId: String) -> Bool {
        return !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Instant zero-latency responses for common queries.
    private func handleQuickSystemQuery(prompt: String) -> String? {
        let lower = prompt.lowercased()

        // Current time
        if lower.contains("time is it") || lower == "what time is it" || lower == "time" {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "It is currently \(formatter.string(from: Date()))."
        }

        // Current date
        if lower.contains("what's the date") || lower.contains("today's date") || lower.contains("what day is it") {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            return "Today is \(formatter.string(from: Date()))."
        }

        // Battery level
        if lower.contains("battery") {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            process.arguments = ["-g", "batt"]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            if let match = output.range(of: "\\d+%", options: .regularExpression) {
                let percent = String(output[match])
                return "Your battery is currently at \(percent)."
            }
        }

        return nil
    }
}
