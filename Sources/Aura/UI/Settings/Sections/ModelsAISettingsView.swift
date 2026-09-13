import SwiftUI

/// Models & AI settings section for managing LLM providers, dynamic model discovery,
/// API credentials, and inference parameters, styled with the obsidian liquid-glass system.
public struct ModelsAISettingsView: View {
    @AppStorage("selectedProvider") private var selectedProvider: String = "Google Gemini"
    @AppStorage("selectedModel") private var selectedModel: String = ""
    @AppStorage("googleApiKey") private var googleApiKey: String = ""
    @AppStorage("openAiApiKey") private var openAiApiKey: String = ""
    @AppStorage("anthropicApiKey") private var anthropicApiKey: String = ""
    @AppStorage("groqApiKey") private var groqApiKey: String = ""
    @AppStorage("deepseekApiKey") private var deepseekApiKey: String = ""
    @AppStorage("mistralApiKey") private var mistralApiKey: String = ""
    @AppStorage("customApiKey") private var customApiKey: String = ""
    @AppStorage("customBaseUrl") private var customBaseUrl: String = "http://localhost:8000/v1"
    @AppStorage("llmTemperature") private var temperature: Double = 0.7
    @AppStorage("llmMaxTokens") private var maxTokens: Int = 150

    @State private var showKey: Bool = false
    @State private var isVerifying: Bool = false
    @State private var verifyStatus: String? = nil
    @State private var verifySuccess: Bool = false

    @State private var availableModels: [DiscoveredModel] = []
    @State private var isLoadingModels: Bool = false
    @State private var modelsFetchError: String? = nil

    public init() {}

    private var activeConfig: ProviderConfig {
        ProviderRegistry.shared.find(idOrName: selectedProvider)
    }

    private var currentModelObj: DiscoveredModel? {
        availableModels.first(where: { $0.modelId == selectedModel })
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text("Models & Intelligence")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()

                        // Status Pill in Header
                        HStack(spacing: 6) {
                            Circle()
                                .fill(availableModels.isEmpty ? ControlCenterTokens.Colors.accentAmber : ControlCenterTokens.Colors.accentEmerald)
                                .frame(width: 7, height: 7)
                            Text(availableModels.isEmpty ? "Credentials Needed" : "\(availableModels.count) Models Available")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }

                    Text("Configure your conversational AI provider, connect local or remote OpenAI-compatible endpoints, and fine-tune response reasoning.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // ==========================================
                // 1. PROVIDER & CREDENTIALS CARD
                // ==========================================
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack(alignment: .center) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentPurple.opacity(0.18))
                                    .frame(width: 30, height: 30)

                                Image(systemName: "server.rack")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(ControlCenterTokens.Colors.accentPurple)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Inference Engine & Connection")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Select a provider and authenticate endpoint access.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.45))
                            }

                            Spacer()

                            // Credential Source Pill
                            Text(LLMService.shared.credentialSource.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3.5)
                                .background(ControlCenterTokens.Colors.accentPurple.opacity(0.15))
                                .foregroundColor(ControlCenterTokens.Colors.accentPurple)
                                .cornerRadius(5)
                        }

                        Divider().overlay(Color.white.opacity(0.06))

                        // Provider Dropdown
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PROVIDER")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.45))

                            Picker("", selection: $selectedProvider) {
                                ForEach(ProviderRegistry.shared.providers) { p in
                                    Text(p.displayName).tag(p.displayName)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 340, alignment: .leading)
                            .onChange(of: selectedProvider) { _, newProvider in
                                let newConfig = ProviderRegistry.shared.find(idOrName: newProvider)
                                availableModels = []
                                modelsFetchError = nil

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

                        // Custom / OpenAI-Compatible Endpoint URL
                        if activeConfig.providerId == "custom" || activeConfig.providerId == "ollama" {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("BASE URL")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.45))
                                    Spacer()
                                    Text("OpenAI-Compatible")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.35))
                                }

                                TextField("http://localhost:8000/v1", text: $customBaseUrl)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding(9)
                                    .background(ControlCenterTokens.Colors.sunkenSurface)
                                    .cornerRadius(7)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                    )

                                Text("Enter any OpenAI-compatible base URL (local inference server, proxy, or remote gateway).")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.25))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
                            )
                        }

                        // API Key Input
                        if activeConfig.requiresApiKey || activeConfig.providerId == "custom" {
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
                                .padding(9)
                                .background(ControlCenterTokens.Colors.sunkenSurface)
                                .cornerRadius(7)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }

                        // Action Bar: Fetch Models & Test Connection
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                // Primary "Fetch Models" Action Button
                                Button {
                                    Task {
                                        await refreshModels()
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if isLoadingModels {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        Text(isLoadingModels ? "Fetching Models..." : "Fetch Models")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.09))
                                    .foregroundColor(.white)
                                    .cornerRadius(7)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoadingModels)

                                // Test Connection Ping Button
                                Button(action: verifyKey) {
                                    HStack(spacing: 6) {
                                        if isVerifying {
                                            ProgressView()
                                                .controlSize(.small)
                                            Text("Testing...")
                                                .font(.system(size: 12, weight: .semibold))
                                        } else {
                                            Image(systemName: "bolt.horizontal.fill")
                                                .font(.system(size: 11))
                                            Text("Test Latency")
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(ControlCenterTokens.Colors.accentIndigo.opacity(0.3))
                                    .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                                    .cornerRadius(7)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .strokeBorder(ControlCenterTokens.Colors.accentIndigo.opacity(0.35), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isVerifying || (activeConfig.requiresApiKey && activeApiKey.isEmpty))

                                Spacer()

                                // Ping Status Pill (if available)
                                if let status = verifyStatus {
                                    HStack(spacing: 4) {
                                        Image(systemName: verifySuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(verifySuccess ? ControlCenterTokens.Colors.accentEmerald : ControlCenterTokens.Colors.accentCoral)
                                        Text(status)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(verifySuccess ? ControlCenterTokens.Colors.accentEmerald : ControlCenterTokens.Colors.accentCoral)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background((verifySuccess ? ControlCenterTokens.Colors.accentEmerald : ControlCenterTokens.Colors.accentCoral).opacity(0.12))
                                    .cornerRadius(6)
                                }
                            }

                            // Model Discovery Status Banner
                            if let err = modelsFetchError {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(ControlCenterTokens.Colors.accentCoral)
                                    Text(err)
                                        .font(.system(size: 11))
                                        .foregroundColor(ControlCenterTokens.Colors.accentCoral)
                                        .lineLimit(2)
                                    Spacer()
                                }
                                .padding(10)
                                .background(ControlCenterTokens.Colors.accentCoral.opacity(0.08))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(ControlCenterTokens.Colors.accentCoral.opacity(0.25), lineWidth: 1)
                                )
                            } else if !availableModels.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                                    Text("✓ Models verified (\(availableModels.count) available from endpoint)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(ControlCenterTokens.Colors.accentEmerald.opacity(0.08))
                                .cornerRadius(6)
                            }
                        }
                    }
                }

                // ==========================================
                // 2. ACTIVE MODEL SELECTION CARD
                // ==========================================
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentCyan.opacity(0.18))
                                    .frame(width: 30, height: 30)

                                Image(systemName: "cpu.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(ControlCenterTokens.Colors.accentCyan)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Active Conversational Model")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Model queried dynamically via the OpenAI API contract.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.45))
                            }

                            Spacer()

                            if !selectedModel.isEmpty {
                                Text(selectedModel)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3.5)
                                    .background(ControlCenterTokens.Colors.accentCyan.opacity(0.15))
                                    .foregroundColor(ControlCenterTokens.Colors.accentCyan)
                                    .cornerRadius(5)
                            }
                        }

                        Divider().overlay(Color.white.opacity(0.06))

                        if availableModels.isEmpty {
                            // Clean Empty State
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 34, height: 34)
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("No models discovered yet")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                    Text("Enter your credentials above and click \"Fetch Models\" to load models from this endpoint.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.45))
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(ControlCenterTokens.Colors.sunkenSurface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        } else {
                            // Model Dropdown
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SELECT MODEL (MULTI-TURN & FUNCTION CALLING)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.45))

                                Picker("", selection: $selectedModel) {
                                    ForEach(availableModels) { model in
                                        Text(model.displayName).tag(model.modelId)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: 380, alignment: .leading)

                                // Active Model Diagnostics Chips
                                if let model = currentModelObj {
                                    HStack(spacing: 8) {
                                        HStack(spacing: 4) {
                                            Text("ID:")
                                                .foregroundColor(.white.opacity(0.4))
                                            Text(model.modelId)
                                                .foregroundColor(.white.opacity(0.85))
                                        }
                                        .font(.system(size: 10, design: .monospaced))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(4)

                                        if let ctx = model.contextWindow {
                                            HStack(spacing: 4) {
                                                Text("Context:")
                                                    .foregroundColor(.white.opacity(0.4))
                                                Text("\(ctx / 1000)k tokens")
                                                    .foregroundColor(.white.opacity(0.85))
                                            }
                                            .font(.system(size: 10, design: .monospaced))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(4)
                                        }

                                        if model.isRecommended {
                                            Text("RECOMMENDED")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(ControlCenterTokens.Colors.accentEmerald.opacity(0.15))
                                                .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                }

                // ==========================================
                // 3. INFERENCE & RESPONSE PARAMETERS CARD
                // ==========================================
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentAmber.opacity(0.18))
                                    .frame(width: 30, height: 30)

                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(ControlCenterTokens.Colors.accentAmber)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Inference Parameters")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Adjust temperature and length constraints for spoken responses.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.45))
                            }

                            Spacer()
                        }

                        Divider().overlay(Color.white.opacity(0.06))

                        // Temperature Slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("TEMPERATURE (CREATIVITY)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.45))
                                Spacer()
                                HStack(spacing: 5) {
                                    Text(temperatureQualityTag(temp: temperature))
                                        .font(.system(size: 10))
                                        .foregroundColor(ControlCenterTokens.Colors.accentAmber)
                                    Text(String(format: "%.2f", temperature))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }

                            Slider(value: $temperature, in: 0.0...1.0, step: 0.05)
                                .tint(ControlCenterTokens.Colors.accentAmber)
                        }

                        // Max Tokens Slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("MAX RESPONSE TOKENS")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.45))
                                Spacer()
                                HStack(spacing: 5) {
                                    Text("~\(maxTokens / 4) spoken words")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("\(maxTokens)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }

                            Slider(value: Binding(
                                get: { Double(maxTokens) },
                                set: { maxTokens = Int($0) }
                            ), in: 50...400, step: 25)
                            .tint(ControlCenterTokens.Colors.accentAmber)
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

    private func temperatureQualityTag(temp: Double) -> String {
        if temp < 0.25 {
            return "Precise & Deterministic"
        } else if temp < 0.65 {
            return "Balanced Voice"
        } else {
            return "Creative & Expressive"
        }
    }

    // MARK: - Auto-Detection & Population
    private func autoDetectEnvironmentAndPopulate() {
        let env = ProcessInfo.processInfo.environment

        if UserDefaults.standard.string(forKey: "selectedProvider") == nil {
            if let auto = ProviderRegistry.shared.autoDetectActiveEnvironment() {
                selectedProvider = auto.provider.displayName
                populateKeyField(for: auto.provider.providerId, key: auto.apiKey)
            }
        } else {
            let config = ProviderRegistry.shared.find(idOrName: selectedProvider)
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
        case "custom": if customApiKey.isEmpty { customApiKey = key }
        default: break
        }
    }

    // MARK: - Dynamic Model Refresh
    private func refreshModels() async {
        await MainActor.run {
            self.isLoadingModels = true
            self.modelsFetchError = nil
        }
        let key = activeApiKey
        let url = customBaseUrl.isEmpty ? nil : customBaseUrl
        do {
            let models = try await ModelDiscoveryService.shared.fetchModels(
                provider: selectedProvider,
                apiKey: key,
                customBaseURL: url,
                forceRefresh: true
            )
            await MainActor.run {
                self.availableModels = models
                self.isLoadingModels = false
                self.modelsFetchError = nil

                if !models.contains(where: { $0.modelId == self.selectedModel }) {
                    if let rec = models.first(where: { $0.isRecommended }) ?? models.first {
                        self.selectedModel = rec.modelId
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.availableModels = []
                self.isLoadingModels = false
                self.modelsFetchError = error.localizedDescription
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
        case "custom": return customApiKey
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
        case "custom": return $customApiKey
        default: return $customApiKey
        }
    }

    private var apiKeyFieldLabel: String {
        if activeConfig.providerId == "custom" {
            return "API Key / Bearer Token (Optional)"
        }
        return "\(activeConfig.displayName) API Key"
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
                self.verifyStatus = res.success ? "Latency: \(res.latencyMs)ms" : (res.error ?? "Failed")
            }
        }
    }
}

