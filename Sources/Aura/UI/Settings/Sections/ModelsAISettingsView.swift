import SwiftUI

/// Models & AI settings section for managing LLM providers, dynamic model discovery,
/// API credentials, and inference parameters, styled with the obsidian liquid-glass system.
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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Models & Intelligence")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Select your preferred AI provider, manage API credentials, and tune response parameters.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                // 1. Provider & Model Card
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentPurple.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "brain")
                                    .font(.system(size: 14))
                                    .foregroundColor(ControlCenterTokens.Colors.accentPurple)
                            }

                            Text("AI Engine Selection")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.06))

                        // Provider Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ACTIVE PROVIDER")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.45))

                            Picker("", selection: $selectedProvider) {
                                ForEach(ProviderRegistry.shared.providers) { p in
                                    Text(p.displayName).tag(p.displayName)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 320, alignment: .leading)
                            .onChange(of: selectedProvider) { _, newProvider in
                                let newConfig = ProviderRegistry.shared.find(idOrName: newProvider)
                                selectedModel = newConfig.defaultModel

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
                                Text("MODEL (CHAT & TOOL CALLING)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.45))
                                Spacer()
                                if isLoadingModels {
                                    ProgressView()
                                        .controlSize(.mini)
                                        .scaleEffect(0.6)
                                }
                                Button {
                                    Task {
                                        await refreshModels()
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                                .help("Refresh available models from provider API")
                            }

                            if activeConfig.providerId == "custom" && availableModels.isEmpty {
                                TextField("Model name (e.g. llama3.2, mistral)", text: $customModelName)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12))
                                    .padding(8)
                                    .background(ControlCenterTokens.Colors.sunkenSurface)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            } else {
                                Picker("", selection: $selectedModel) {
                                    ForEach(availableModels) { model in
                                        Text(model.displayName).tag(model.modelId)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: 360, alignment: .leading)
                            }
                        }

                        // Custom Base URL
                        if activeConfig.providerId == "custom" || activeConfig.providerId == "ollama" {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("ENDPOINT URL")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.45))
                                    Spacer()
                                    Text("Default: \(activeConfig.defaultBaseURL)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.4))
                                }

                                TextField("http://...", text: $customBaseUrl)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding(8)
                                    .background(ControlCenterTokens.Colors.sunkenSurface)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }

                // 2. API Credentials Card
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentIndigo.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "key.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                            }

                            Text("API Credentials")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            Text(LLMService.shared.credentialSource)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(ControlCenterTokens.Colors.accentEmerald.opacity(0.2))
                                .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                                .cornerRadius(4)
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.06))

                        if activeConfig.requiresApiKey {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(apiKeyFieldLabel.uppercased())
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.45))
                                    Spacer()
                                    if let helpURL = activeConfig.helpURL, let url = URL(string: helpURL) {
                                        Link("Get API Key ↗", destination: url)
                                            .font(.system(size: 11))
                                            .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                                    }
                                }

                                HStack(spacing: 8) {
                                    if showKey {
                                        TextField(apiKeyPlaceholder, text: activeKeyBinding)
                                            .textFieldStyle(.plain)
                                            .font(.system(size: 12, design: .monospaced))
                                    } else {
                                        SecureField(apiKeyPlaceholder, text: activeKeyBinding)
                                            .textFieldStyle(.plain)
                                            .font(.system(size: 12, design: .monospaced))
                                    }

                                    Button {
                                        showKey.toggle()
                                    } label: {
                                        Image(systemName: showKey ? "eye.slash" : "eye")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(8)
                                .background(ControlCenterTokens.Colors.sunkenSurface)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                        } else {
                            Text("No API key required for \(activeConfig.displayName).")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        // Connection Test Button
                        HStack {
                            Button(action: verifyKey) {
                                HStack(spacing: 6) {
                                    if isVerifying {
                                        ProgressView()
                                            .controlSize(.mini)
                                            .scaleEffect(0.65)
                                        Text("Verifying...")
                                            .font(.system(size: 12, weight: .semibold))
                                    } else {
                                        Image(systemName: "bolt.horizontal.fill")
                                            .font(.system(size: 11))
                                        Text("Test Connection")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ControlCenterTokens.Colors.accentIndigo)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(isVerifying || (activeConfig.requiresApiKey && activeApiKey.isEmpty))

                            if let status = verifyStatus {
                                HStack(spacing: 5) {
                                    Image(systemName: verifySuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(verifySuccess ? ControlCenterTokens.Colors.accentEmerald : Color.red)
                                    Text(status)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(verifySuccess ? ControlCenterTokens.Colors.accentEmerald : Color.red)
                                }
                                .padding(.leading, 8)
                            }

                            Spacer()
                        }
                    }
                }

                // 3. Response Tuning Parameters
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentAmber.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 13))
                                    .foregroundColor(ControlCenterTokens.Colors.accentAmber)
                            }

                            Text("Response Parameters")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.06))

                        // Temperature
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("TEMPERATURE (CREATIVITY)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.45))
                                Spacer()
                                Text(String(format: "%.2f", temperature))
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                            }

                            Slider(value: $temperature, in: 0.0...1.0, step: 0.05)
                        }

                        // Max Tokens
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("MAX RESPONSE TOKENS")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.45))
                                Spacer()
                                Text("\(maxTokens)")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                            }

                            Slider(value: Binding(
                                get: { Double(maxTokens) },
                                set: { maxTokens = Int($0) }
                            ), in: 50...400, step: 25)
                        }
                    }
                }
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

        if UserDefaults.standard.string(forKey: "selectedProvider") == nil {
            if let auto = ProviderRegistry.shared.autoDetectActiveEnvironment() {
                selectedProvider = auto.provider.displayName
                selectedModel = auto.provider.defaultModel
                populateKeyField(for: auto.provider.providerId, key: auto.apiKey)
            }
        } else {
            let config = ProviderRegistry.shared.find(idOrName: selectedProvider)
            if !LLMService.shared.isModelCompatibleWithProvider(model: selectedModel, providerId: config.providerId) {
                selectedModel = config.defaultModel
            }

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
