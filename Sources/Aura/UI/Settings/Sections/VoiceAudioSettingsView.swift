import AVFoundation
import SwiftUI

/// Voice and audio settings section for managing separate STT and TTS engines
/// across Apple Native, Groq, and ElevenLabs (3x3 = 9 configurations).
public struct VoiceAudioSettingsView: View {
    @ObservedObject public var appState: AppState

    // MARK: - Engine Selectors
    @AppStorage("sttEngine") private var sttEngine: String = "apple"
    @AppStorage("ttsEngine") private var ttsEngine: String = "apple"

    // MARK: - STT Configuration (Independent Keys)
    @AppStorage("groqSTTApiKey") private var groqSTTApiKey: String = ""
    @AppStorage("groqSTTModel") private var groqSTTModel: String = "whisper-large-v3-turbo"

    @AppStorage("elevenLabsSTTApiKey") private var elevenLabsSTTApiKey: String = ""
    @AppStorage("elevenLabsSTTModel") private var elevenLabsSTTModel: String = "scribe_v1"

    // MARK: - TTS Configuration (Independent Keys)
    @AppStorage("spokenFeedbackEnabled") private var spokenFeedbackEnabled: Bool = true
    @AppStorage("selectedVoiceIdentifier") private var selectedVoiceIdentifier: String = "com.apple.voice.compact.en-US.Samantha"
    @AppStorage("speechRate") private var speechRate: Double = 0.52

    @AppStorage("groqTTSApiKey") private var groqTTSApiKey: String = ""
    @AppStorage("groqTTSVoice") private var groqTTSVoice: String = "autumn"

    @AppStorage("elevenLabsTTSApiKey") private var elevenLabsTTSApiKey: String = ""
    @AppStorage("elevenLabsTTSModel") private var elevenLabsTTSModel: String = "eleven_flash_v2_5"
    @AppStorage("elevenLabsTTSVoiceId") private var elevenLabsTTSVoiceId: String = "EXAVITQu4vr4xnSDxMaL"

    // MARK: - Media Ducking
    @AppStorage("pauseMusicOnListen") private var pauseMusicOnListen: Bool = true
    @AppStorage("pauseSpotifyOnListen") private var pauseSpotifyOnListen: Bool = true

    // MARK: - Dynamic State
    @State private var showGroqSTTKey: Bool = false
    @State private var showElevenSTTKey: Bool = false
    @State private var showGroqTTSKey: Bool = false
    @State private var showElevenTTSKey: Bool = false

    @State private var sttGroqModels: [String] = []
    @State private var sttElevenModels: [String] = []
    @State private var isFetchingSTT: Bool = false
    @State private var sttFetchError: String? = nil

    @State private var ttsGroqVoices: [String] = []
    @State private var ttsElevenVoices: [ElevenVoice] = []
    @State private var ttsElevenModels: [String] = []
    @State private var isFetchingTTS: Bool = false
    @State private var ttsFetchError: String? = nil

    private var availableAppleVoices: [AVSpeechSynthesisVoice] {
        let all = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.starts(with: "en") }
            .sorted { $0.name < $1.name }
        return all.isEmpty ? [AVSpeechSynthesisVoice(language: "en-US")].compactMap { $0 } : all
    }

    public init(appState: AppState = .shared) {
        self.appState = appState
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Voice & Audio")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Configure independent engines for Speech-to-Text and Text-to-Speech across Apple Native, Groq, and ElevenLabs.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                // ==========================================
                // 1. SPEECH-TO-TEXT (STT) CONFIGURATION
                // ==========================================
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentCyan.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "mic.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(ControlCenterTokens.Colors.accentCyan)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Speech-to-Text (STT) Engine")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Select the engine that listens to your microphone.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()

                            Text(sttEngine.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ControlCenterTokens.Colors.accentCyan.opacity(0.15))
                                .foregroundColor(ControlCenterTokens.Colors.accentCyan)
                                .cornerRadius(4)
                        }

                        Divider().overlay(Color.white.opacity(0.06))

                        // STT Provider Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("STT PROVIDER")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.45))

                            Picker("", selection: $sttEngine) {
                                Text("Apple Native (On-Device)").tag("apple")
                                Text("Groq Whisper (Turbo LPU)").tag("groq")
                                Text("ElevenLabs Scribe").tag("elevenlabs")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Groq STT Settings
                        if sttEngine == "groq" {
                            VStack(alignment: .leading, spacing: 12) {
                                keyInputField(
                                    label: "GROQ STT API KEY",
                                    placeholder: "gsk_...",
                                    text: $groqSTTApiKey,
                                    isSecured: !showGroqSTTKey,
                                    onToggleShow: { showGroqSTTKey.toggle() }
                                )

                                HStack {
                                    Button {
                                        fetchGroqSTTModels()
                                    } label: {
                                        HStack(spacing: 6) {
                                            if isFetchingSTT {
                                                ProgressView().controlSize(.small)
                                            } else {
                                                Image(systemName: "arrow.clockwise")
                                                    .font(.system(size: 11))
                                            }
                                            Text("Fetch Models")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.08))
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)

                                    if let err = sttFetchError {
                                        Text(err)
                                            .font(.system(size: 11))
                                            .foregroundColor(ControlCenterTokens.Colors.accentCoral)
                                    } else if !sttGroqModels.isEmpty {
                                        Text("✓ Models verified")
                                            .font(.system(size: 11))
                                            .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                                    }
                                }

                                if !sttGroqModels.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("WHISPER MODEL")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.45))

                                        Picker("", selection: $groqSTTModel) {
                                            ForEach(sttGroqModels, id: \.self) { m in
                                                Text(m).tag(m)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: 320, alignment: .leading)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(8)
                        }

                        // ElevenLabs STT Settings
                        if sttEngine == "elevenlabs" {
                            VStack(alignment: .leading, spacing: 12) {
                                keyInputField(
                                    label: "ELEVENLABS STT API KEY",
                                    placeholder: "sk_...",
                                    text: $elevenLabsSTTApiKey,
                                    isSecured: !showElevenSTTKey,
                                    onToggleShow: { showElevenSTTKey.toggle() }
                                )

                                HStack {
                                    Button {
                                        fetchElevenLabsSTTModels()
                                    } label: {
                                        HStack(spacing: 6) {
                                            if isFetchingSTT {
                                                ProgressView().controlSize(.small)
                                            } else {
                                                Image(systemName: "arrow.clockwise")
                                                    .font(.system(size: 11))
                                            }
                                            Text("Fetch Models")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.08))
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)

                                    if let err = sttFetchError {
                                        Text(err)
                                            .font(.system(size: 11))
                                            .foregroundColor(ControlCenterTokens.Colors.accentCoral)
                                    } else if !sttElevenModels.isEmpty {
                                        Text("✓ Model verified")
                                            .font(.system(size: 11))
                                            .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                                    }
                                }

                                if !sttElevenModels.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("SCRIBE MODEL")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.45))

                                        Picker("", selection: $elevenLabsSTTModel) {
                                            ForEach(sttElevenModels, id: \.self) { m in
                                                Text(m).tag(m)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: 320, alignment: .leading)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(8)
                        }

                        // Live Equalizer Bar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("MIC INPUT SPECTRUM")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.45))
                                Spacer()
                                Text(String(format: "%.0f%%", appState.audioLevel * 100))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            ControlCenterEqualizerView(audioLevel: appState.audioLevel, barCount: 20, height: 20)
                        }
                    }
                }

                // ==========================================
                // 2. TEXT-TO-SPEECH (TTS) CONFIGURATION
                // ==========================================
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentCoral.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(ControlCenterTokens.Colors.accentCoral)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Text-to-Speech (TTS) Voice Engine")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Select the engine that speaks agent answers aloud.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()

                            Text(ttsEngine.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ControlCenterTokens.Colors.accentCoral.opacity(0.15))
                                .foregroundColor(ControlCenterTokens.Colors.accentCoral)
                                .cornerRadius(4)
                        }

                        Divider().overlay(Color.white.opacity(0.06))

                        Toggle("Enable spoken audio responses", isOn: $spokenFeedbackEnabled)
                            .toggleStyle(.switch)
                            .foregroundColor(.white.opacity(0.9))

                        if spokenFeedbackEnabled {
                            // TTS Provider Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("TTS PROVIDER")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.45))

                                Picker("", selection: $ttsEngine) {
                                    Text("Apple Native (macOS Voices)").tag("apple")
                                    Text("Groq Orpheus (Turbo LPU)").tag("groq")
                                    Text("ElevenLabs Voice Synthesis").tag("elevenlabs")
                                }
                                .pickerStyle(.segmented)
                            }

                            // Apple Native TTS
                            if ttsEngine == "apple" {
                                VStack(alignment: .leading, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("MACOS SYSTEM VOICE")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.45))

                                        Picker("", selection: $selectedVoiceIdentifier) {
                                            ForEach(availableAppleVoices, id: \.identifier) { voice in
                                                Text("\(voice.name) (\(voice.language))").tag(voice.identifier)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: 340, alignment: .leading)
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text("SPEECH RATE")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.45))
                                            Spacer()
                                            Text(String(format: "%.2fx", speechRate * 2))
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white)
                                        }
                                        Slider(value: $speechRate, in: 0.3...0.7, step: 0.02)
                                    }
                                }
                            }

                            // Groq Orpheus TTS
                            if ttsEngine == "groq" {
                                VStack(alignment: .leading, spacing: 12) {
                                    keyInputField(
                                        label: "GROQ TTS API KEY",
                                        placeholder: "gsk_...",
                                        text: $groqTTSApiKey,
                                        isSecured: !showGroqTTSKey,
                                        onToggleShow: { showGroqTTSKey.toggle() }
                                    )

                                    HStack {
                                        Button {
                                            fetchGroqTTSVoices()
                                        } label: {
                                            HStack(spacing: 6) {
                                                if isFetchingTTS {
                                                    ProgressView().controlSize(.small)
                                                } else {
                                                    Image(systemName: "arrow.clockwise")
                                                        .font(.system(size: 11))
                                                }
                                                Text("Fetch Voices")
                                                    .font(.system(size: 11, weight: .semibold))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.white.opacity(0.08))
                                            .foregroundColor(.white)
                                            .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)

                                        if let err = ttsFetchError {
                                            Text(err)
                                                .font(.system(size: 11))
                                                .foregroundColor(ControlCenterTokens.Colors.accentCoral)
                                        } else if !ttsGroqVoices.isEmpty {
                                            Text("✓ Voices loaded")
                                                .font(.system(size: 11))
                                                .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                                        }
                                    }

                                    if !ttsGroqVoices.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("ORPHEUS VOICE")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.45))

                                            Picker("", selection: $groqTTSVoice) {
                                                ForEach(ttsGroqVoices, id: \.self) { v in
                                                    Text(v.capitalized).tag(v)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .frame(maxWidth: 320, alignment: .leading)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                            }

                            // ElevenLabs TTS
                            if ttsEngine == "elevenlabs" {
                                VStack(alignment: .leading, spacing: 12) {
                                    keyInputField(
                                        label: "ELEVENLABS TTS API KEY",
                                        placeholder: "sk_...",
                                        text: $elevenLabsTTSApiKey,
                                        isSecured: !showElevenTTSKey,
                                        onToggleShow: { showElevenTTSKey.toggle() }
                                    )

                                    HStack {
                                        Button {
                                            fetchElevenLabsTTSVoicesAndModels()
                                        } label: {
                                            HStack(spacing: 6) {
                                                if isFetchingTTS {
                                                    ProgressView().controlSize(.small)
                                                } else {
                                                    Image(systemName: "arrow.clockwise")
                                                        .font(.system(size: 11))
                                                }
                                                Text("Fetch Voices & Models")
                                                    .font(.system(size: 11, weight: .semibold))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.white.opacity(0.08))
                                            .foregroundColor(.white)
                                            .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)

                                        if let err = ttsFetchError {
                                            Text(err)
                                                .font(.system(size: 11))
                                                .foregroundColor(ControlCenterTokens.Colors.accentCoral)
                                        } else if !ttsElevenVoices.isEmpty {
                                            Text("✓ \(ttsElevenVoices.count) voices loaded")
                                                .font(.system(size: 11))
                                                .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                                        }
                                    }

                                    if !ttsElevenModels.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("ELEVENLABS MODEL")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.45))

                                            Picker("", selection: $elevenLabsTTSModel) {
                                                ForEach(ttsElevenModels, id: \.self) { m in
                                                    Text(m).tag(m)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .frame(maxWidth: 320, alignment: .leading)
                                        }
                                    }

                                    if !ttsElevenVoices.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("ACCOUNT VOICE")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.45))

                                            Picker("", selection: $elevenLabsTTSVoiceId) {
                                                ForEach(ttsElevenVoices) { voice in
                                                    Text("\(voice.name)\(voice.category != nil ? " (\(voice.category!))" : "")")
                                                        .tag(voice.id)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .frame(maxWidth: 340, alignment: .leading)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                            }

                            // Preview Button
                            HStack {
                                Button {
                                    SpeechSynthesizer.shared.speak(text: "Hello! This is how I sound with your current settings.")
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 10))
                                        Text("Preview Selected Voice")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(ControlCenterTokens.Colors.accentIndigo)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                Spacer()
                            }
                        }
                    }
                }

                // ==========================================
                // 3. MEDIA DUCKING
                // ==========================================
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentIndigo.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                            }

                            Text("Media Playback Ducking")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()
                        }

                        Divider().overlay(Color.white.opacity(0.06))

                        Toggle("Pause Apple Music while listening or speaking", isOn: $pauseMusicOnListen)
                            .toggleStyle(.switch)
                            .foregroundColor(.white.opacity(0.9))

                        Toggle("Pause Spotify while listening or speaking", isOn: $pauseSpotifyOnListen)
                            .toggleStyle(.switch)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            autoPopulateFromEnvironment()
            // Auto-load available models/voices if keys exist
            if sttEngine == "groq" && !groqSTTApiKey.isEmpty { fetchGroqSTTModels() }
            if sttEngine == "elevenlabs" && !elevenLabsSTTApiKey.isEmpty { fetchElevenLabsSTTModels() }
            if ttsEngine == "groq" && !groqTTSApiKey.isEmpty { fetchGroqTTSVoices() }
            if ttsEngine == "elevenlabs" && !elevenLabsTTSApiKey.isEmpty { fetchElevenLabsTTSVoicesAndModels() }
        }
    }

    // MARK: - Reusable Key Input Field
    @ViewBuilder
    private func keyInputField(label: String, placeholder: String, text: Binding<String>, isSecured: Bool, onToggleShow: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))

            HStack(spacing: 8) {
                if isSecured {
                    SecureField(placeholder, text: text)
                        .textFieldStyle(.plain)
                        .padding(7)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                } else {
                    TextField(placeholder, text: text)
                        .textFieldStyle(.plain)
                        .padding(7)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                }

                Button(action: onToggleShow) {
                    Image(systemName: isSecured ? "eye" : "eye.slash")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Environment Variable Auto-Population
    private func autoPopulateFromEnvironment() {
        if groqSTTApiKey.isEmpty, let env = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !env.isEmpty {
            groqSTTApiKey = env
        }
        if groqTTSApiKey.isEmpty, let env = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !env.isEmpty {
            groqTTSApiKey = env
        }

        let elEnv = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? ProcessInfo.processInfo.environment["XI_API_KEY"]
        if let elEnv, !elEnv.isEmpty {
            if elevenLabsSTTApiKey.isEmpty {
                elevenLabsSTTApiKey = elEnv
            }
            if elevenLabsTTSApiKey.isEmpty {
                elevenLabsTTSApiKey = elEnv
            }
        }
    }

    // MARK: - Fetch Actions
    private func fetchGroqSTTModels() {
        isFetchingSTT = true
        sttFetchError = nil
        Task {
            do {
                let models = try await VoiceDiscoveryService.shared.fetchGroqSTTModels(apiKey: groqSTTApiKey)
                await MainActor.run {
                    self.sttGroqModels = models
                    if !models.contains(self.groqSTTModel), let first = models.first {
                        self.groqSTTModel = first
                    }
                    self.isFetchingSTT = false
                }
            } catch {
                await MainActor.run {
                    self.sttGroqModels = []
                    self.sttFetchError = error.localizedDescription
                    self.isFetchingSTT = false
                }
            }
        }
    }

    private func fetchElevenLabsSTTModels() {
        isFetchingSTT = true
        sttFetchError = nil
        Task {
            do {
                let models = try await VoiceDiscoveryService.shared.fetchElevenLabsSTTModels(apiKey: elevenLabsSTTApiKey)
                await MainActor.run {
                    self.sttElevenModels = models
                    if !models.contains(self.elevenLabsSTTModel), let first = models.first {
                        self.elevenLabsSTTModel = first
                    }
                    self.isFetchingSTT = false
                }
            } catch {
                await MainActor.run {
                    self.sttElevenModels = []
                    self.sttFetchError = error.localizedDescription
                    self.isFetchingSTT = false
                }
            }
        }
    }

    private func fetchGroqTTSVoices() {
        isFetchingTTS = true
        ttsFetchError = nil
        Task {
            do {
                let voices = try await VoiceDiscoveryService.shared.fetchGroqTTSVoices(apiKey: groqTTSApiKey)
                await MainActor.run {
                    self.ttsGroqVoices = voices
                    if !voices.contains(self.groqTTSVoice), let first = voices.first {
                        self.groqTTSVoice = first
                    }
                    self.isFetchingTTS = false
                }
            } catch {
                await MainActor.run {
                    self.ttsGroqVoices = []
                    self.ttsFetchError = error.localizedDescription
                    self.isFetchingTTS = false
                }
            }
        }
    }

    private func fetchElevenLabsTTSVoicesAndModels() {
        isFetchingTTS = true
        ttsFetchError = nil
        Task {
            do {
                async let voicesTask = VoiceDiscoveryService.shared.fetchElevenLabsVoices(apiKey: elevenLabsTTSApiKey)
                async let modelsTask = VoiceDiscoveryService.shared.fetchElevenLabsTTSModels(apiKey: elevenLabsTTSApiKey)
                let (voices, models) = try await (voicesTask, modelsTask)

                await MainActor.run {
                    self.ttsElevenVoices = voices
                    self.ttsElevenModels = models
                    if !voices.contains(where: { $0.id == self.elevenLabsTTSVoiceId }), let first = voices.first {
                        self.elevenLabsTTSVoiceId = first.id
                    }
                    if !models.contains(self.elevenLabsTTSModel), let first = models.first {
                        self.elevenLabsTTSModel = first
                    }
                    self.isFetchingTTS = false
                }
            } catch {
                await MainActor.run {
                    self.ttsElevenVoices = []
                    self.ttsElevenModels = []
                    self.ttsFetchError = error.localizedDescription
                    self.isFetchingTTS = false
                }
            }
        }
    }
}
