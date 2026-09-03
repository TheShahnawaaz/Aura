import AVFoundation
import SwiftUI

/// Voice and audio settings section for managing microphone input, live speech recognition,
/// media ducking (Apple Music, Spotify), and spoken synthesis playback.
public struct VoiceAudioSettingsView: View {
    @ObservedObject public var appState: AppState

    @AppStorage("speechRate") private var speechRate: Double = 0.52
    @AppStorage("pauseMusicOnListen") private var pauseMusicOnListen: Bool = true
    @AppStorage("pauseSpotifyOnListen") private var pauseSpotifyOnListen: Bool = true
    @AppStorage("spokenFeedbackEnabled") private var spokenFeedbackEnabled: Bool = true
    @AppStorage("selectedVoiceIdentifier") private var selectedVoiceIdentifier: String = "com.apple.voice.compact.en-US.Samantha"

    private var availableVoices: [AVSpeechSynthesisVoice] {
        let all = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.starts(with: "en") }
            .sorted { $0.name < $1.name }
        return all.isEmpty ? [AVSpeechSynthesisVoice(language: "en-US")].compactMap { $0 } : all
    }

    public init(appState: AppState = .shared) {
        self.appState = appState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Voice & Audio")
                        .font(.title2.weight(.bold))
                    Text("Manage microphone input sensitivity, live dictation, media ducking, and spoken response rate.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 1. Microphone & Live Recognition
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Microphone & Dictation", systemImage: "mic.fill")
                            .font(.headline)
                        Spacer()
                        Text("Active")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Engine:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Apple Speech (Native Live Stream)")
                                .font(.subheadline.weight(.medium))
                        }

                        HStack {
                            Text("Input Level Meter:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f%%", appState.audioLevel * 100))
                                .font(.caption.monospacedDigit())
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.primary.opacity(0.08))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.orange)
                                    .frame(width: max(6, geo.size.width * CGFloat(min(1.0, appState.audioLevel * 2.5))))
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // 2. Media Ducking
                VStack(alignment: .leading, spacing: 14) {
                    Label("Media Playback Ducking", systemImage: "speaker.wave.2.fill")
                        .font(.headline)

                    Divider()

                    Toggle("Pause Apple Music while listening or speaking", isOn: $pauseMusicOnListen)
                        .toggleStyle(.switch)

                    Toggle("Pause Spotify while listening or speaking", isOn: $pauseSpotifyOnListen)
                        .toggleStyle(.switch)

                    Text("Aura checks running application identifiers before sending playback events, preventing system picker dialogs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // 3. Spoken Response Feedback (TTS)
                VStack(alignment: .leading, spacing: 14) {
                    Label("Spoken Response Voice (TTS)", systemImage: "waveform.circle.fill")
                        .font(.headline)

                    Divider()

                    Toggle("Enable spoken audio responses", isOn: $spokenFeedbackEnabled)
                        .toggleStyle(.switch)

                    if spokenFeedbackEnabled {
                        // Voice Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Spoken Voice")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("", selection: $selectedVoiceIdentifier) {
                                ForEach(availableVoices, id: \.identifier) { voice in
                                    Text("\(voice.name) (\(voice.language))").tag(voice.identifier)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Speech Rate:")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.2fx", speechRate * 2))
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                            }
                            Slider(value: $speechRate, in: 0.3...0.7, step: 0.02)
                        }

                        Button {
                            SpeechSynthesizer.shared.speak(text: "Hello! This is how I sound with your current settings.")
                        } label: {
                            Label("Preview Voice", systemImage: "play.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
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
    }
}
