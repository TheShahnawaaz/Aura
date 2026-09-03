import SwiftUI

/// Models & AI settings section for managing LLM providers, dynamic model discovery,
/// API credentials, and inference parameters.
public struct ModelsAISettingsView: View {
    @AppStorage("selectedProvider") private var selectedProvider: String = "Google Gemini"
    @AppStorage("selectedModel") private var selectedModel: String = "gemini-2.5-flash"
    @AppStorage("googleApiKey") private var googleApiKey: String = ""
    @AppStorage("openAiApiKey") private var openAiApiKey: String = ""
    @AppStorage("anthropicApiKey") private var anthropicApiKey: String = ""
    @AppStorage("groqApiKey") private var groqApiKey: String = ""
    @AppStorage("deepseekApiKey") private var deepseekApiKey: String = ""
    @AppStorage("mistralApiKey") private var mistralApiKey: String = ""
    @AppStorage("customBaseUrl") private var customBaseUrl: String = ""
    @AppStorage("customModelName") private var customModelName: String = ""
    @AppStorage("llmTemperature") private var temperature: Double = 0.7
    @AppStorage("llmMaxTokens") private var maxTokens: Int = 150

    @State private var showKey: Bool = false
    @State private var isVerifying: Bool = false
    @State private var verifyStatus: String? = nil
    @State private var verifySuccess: Bool = false

    @State private var availableModels: [DiscoveredModel] = []
    @State private var isLoadingModels: Bool = false

    public init() {}

    private var activeConfig: ProviderConfig {
        ProviderRegistry.shared.find(idOrName: selectedProvider)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Models & Intelligence")
                        .font(.title2.weight(.bold))
                    Text("Select your preferred AI provider, manage API credentials, and tune response parameters.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 1. Provider & Model Card
                VStack(alignment: .leading, spacing: 14) {
                    Label("AI Engine Selection", systemImage: "brain")
                        .font(.headline)

                    Divider()

                    // Provider Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Active Provider")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("", selection: $selectedProvider) {
                            ForEach(ProviderRegistry.shared.providers) { p in
                                Text(p.displayName).tag(p.displayName)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 320, alignment: .leading)
                        .onChange(of: selectedProvider) { _, newProvider in
                            let newConfig = ProviderRegistry.shared.find(idOrName: newProvider)
                            // 1. Switch default model to new provider
                            selectedModel = newConfig.defaultModel

                            // 2. Sniff ONLY this provider's environment variables
                            let env = ProcessInfo.processInfo.environment
                            for varName in newConfig.envVarNames {
                                if let val = env[varName], !val.isEmpty {
                                    populateKeyField(for: newConfig.providerId, key: val)
                                    break
                                }
                            }

                            Task {
                                await refreshModels()
                            }
                        }
                    }

                    // Dynamic Model Dropdown
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Model (Chat & Tool Calling)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if isLoadingModels {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 14, height: 14)
                            }
                            Button {
                                Task {
                                    await refreshModels()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Refresh available models from provider API")
                        }

                        if activeConfig.providerId == "custom" && availableModels.isEmpty {
                            TextField("Model name (e.g. llama3.2, mistral)", text: $customModelName)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Picker("", selection: $selectedModel) {
                                ForEach(availableModels) { model in
                                    Text(model.displayName).tag(model.modelId)
                                }
                            }
                            .frame(maxWidth: 360, alignment: .leading)
                        }
                    }

                    // Custom Base URL (shown for Custom/Proxy or if user wants to override)
                    if activeConfig.providerId == "custom" || activeConfig.providerId == "ollama" {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Endpoint URL")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Default: \(activeConfig.defaultBaseURL)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            TextField("http://...", text: $customBaseUrl)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // 2. API Credentials Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("API Credentials", systemImage: "key.fill")
                            .font(.headline)
                        Spacer()
                        // Source Indicator
                        Text(LLMService.shared.credentialSource)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }

                    Divider()

                    if activeConfig.requiresApiKey {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(apiKeyFieldLabel)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let helpURL = activeConfig.helpURL, let url = URL(string: helpURL) {
                                    Link("Get API Key ↗", destination: url)
                                        .font(.caption2)
                                }
                            }

                            HStack {
                                if showKey {
                                    TextField(apiKeyPlaceholder, text: activeKeyBinding)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                } else {
                                    SecureField(apiKeyPlaceholder, text: activeKeyBinding)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                }

                                Button {
                                    showKey.toggle()
                                } label: {
                                    Image(systemName: showKey ? "eye.slash" : "eye")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    } else {
                        Text("No API key required for \(activeConfig.displayName).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Connection Test Button
                    HStack {
                        Button(action: verifyKey) {
                            if isVerifying {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .frame(width: 14, height: 14)
                                    Text("Verifying...")
                                }
                            } else {
                                Label("Test Connection", systemImage: "bolt.horizontal.fill")
                            }
                        }
                        .disabled(isVerifying || (activeConfig.requiresApiKey && activeApiKey.isEmpty))

                        if let status = verifyStatus {
                            HStack(spacing: 5) {
                                Image(systemName: verifySuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(verifySuccess ? .green : .red)
                                Text(status)
                                    .font(.caption)
                                    .foregroundColor(verifySuccess ? .green : .red)
                            }
                            .padding(.leading, 8)
                        }

                        Spacer()
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // 3. Response Tuning Parameters
                VStack(alignment: .leading, spacing: 14) {
                    Label("Response Parameters", systemImage: "slider.horizontal.3")
                        .font(.headline)

                    Divider()

                    // Temperature
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Temperature")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f", temperature))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $temperature, in: 0.0...1.0, step: 0.05)
                    }

                    // Max Tokens
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Max Tokens")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(maxTokens)")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }

                        Slider(value: Binding(
                            get: { Double(maxTokens) },
                            set: { maxTokens = Int($0) }
                        ), in: 50...400, step: 25)
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(24)
        }
        .onAppear {
            autoDetectEnvironmentAndPopulate()
            Task {
                await refreshModels()
            }
        }
    }

    // MARK: - Auto-Detection & Population
    private func autoDetectEnvironmentAndPopulate() {
        let env = ProcessInfo.processInfo.environment

        // 1. If no provider was explicitly saved, auto-select based on detected environment
        if UserDefaults.standard.string(forKey: "selectedProvider") == nil {
            if let auto = ProviderRegistry.shared.autoDetectActiveEnvironment() {
                selectedProvider = auto.provider.displayName
                selectedModel = auto.provider.defaultModel
                populateKeyField(for: auto.provider.providerId, key: auto.apiKey)
            }
        } else {
            // 2. If provider was saved, ensure model is compatible with this provider
            let config = ProviderRegistry.shared.find(idOrName: selectedProvider)
            if !LLMService.shared.isModelCompatibleWithProvider(model: selectedModel, providerId: config.providerId) {
                selectedModel = config.defaultModel
            }

            // 3. If the active key field is empty, check ONLY this provider's env vars
            if activeApiKey.isEmpty {
                for varName in config.envVarNames {
                    if let val = env[varName], !val.isEmpty {
                        populateKeyField(for: config.providerId, key: val)
                        break
                    }
                }
            }
        }
    }

    private func populateKeyField(for providerId: String, key: String) {
        switch providerId {
        case "gemini": if googleApiKey.isEmpty { googleApiKey = key }
        case "openai": if openAiApiKey.isEmpty { openAiApiKey = key }
        case "anthropic": if anthropicApiKey.isEmpty { anthropicApiKey = key }
        case "groq": if groqApiKey.isEmpty { groqApiKey = key }
        case "deepseek": if deepseekApiKey.isEmpty { deepseekApiKey = key }
        case "mistral": if mistralApiKey.isEmpty { mistralApiKey = key }
        default: break
        }
    }

    // MARK: - Dynamic Model Refresh
    private func refreshModels() async {
        isLoadingModels = true
        let key = activeApiKey
        let url = customBaseUrl.isEmpty ? nil : customBaseUrl
        let models = await ModelDiscoveryService.shared.fetchModels(
            provider: selectedProvider,
            apiKey: key,
            customBaseURL: url
        )

        await MainActor.run {
            self.availableModels = models
            self.isLoadingModels = false

            // Auto-select valid model if current selection does not match available models
            if !models.contains(where: { $0.modelId == self.selectedModel }) {
                if let rec = models.first(where: { $0.isRecommended }) ?? models.first {
                    self.selectedModel = rec.modelId
                }
            }
        }
    }

    private var activeApiKey: String {
        switch activeConfig.providerId {
        case "gemini": return googleApiKey
        case "openai": return openAiApiKey
        case "anthropic": return anthropicApiKey
        case "groq": return groqApiKey
        case "deepseek": return deepseekApiKey
        case "mistral": return mistralApiKey
        default: return ""
        }
    }

    private var activeKeyBinding: Binding<String> {
        switch activeConfig.providerId {
        case "gemini": return $googleApiKey
        case "openai": return $openAiApiKey
        case "anthropic": return $anthropicApiKey
        case "groq": return $groqApiKey
        case "deepseek": return $deepseekApiKey
        case "mistral": return $mistralApiKey
        default: return $googleApiKey
        }
    }

    private var apiKeyFieldLabel: String {
        "\(activeConfig.displayName) API Key"
    }

    private var apiKeyPlaceholder: String {
        activeConfig.apiKeyPlaceholder
    }

    private func verifyKey() {
        isVerifying = true
        verifyStatus = nil

        Task {
            let res = await LLMService.shared.pingModel()
            await MainActor.run {
                self.isVerifying = false
                self.verifySuccess = res.success
                self.verifyStatus = res.success ? "Valid Key (\(res.latencyMs)ms)" : (res.error ?? "Invalid Key")
            }
        }
    }
}
