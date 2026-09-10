import SwiftUI

/// Overview / Dashboard tab presenting real-time system health, active model diagnostics,
/// interactive connection test, and live audio monitoring.
public struct OverviewDashboardView: View {
    @ObservedObject public var appState: AppState

    @State private var isTestingModel: Bool = false
    @State private var testResult: TestResult? = nil

    private struct TestResult {
        let success: Bool
        let latencyMs: Int
        let message: String
    }

    public init(appState: AppState = .shared) {
        self.appState = appState
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Section Header
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Overview")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Live telemetry, active model performance, and hardware diagnostics.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    // Engine Status Pill
                    HStack(spacing: 6) {
                        Circle()
                            .fill(stateColor)
                            .frame(width: 7, height: 7)
                            .shadow(color: stateColor.opacity(0.8), radius: 3)

                        Text("60 FPS ENGINE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                }

                // Hero Card with Living Aurora Orb
                ControlCenterGlassCard {
                    HStack(spacing: 20) {
                        LivingAuroraOrbView(appState: appState, size: 60, showSquircleBackground: false)
                            .shadow(color: stateColor.opacity(0.35), radius: 12)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 8) {
                                Text("Aura Agent Core")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text(stateText.uppercased())
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2.5)
                                    .background(stateColor.opacity(0.2))
                                    .foregroundColor(stateColor)
                                    .cornerRadius(4)
                            }

                            Text("Multimodal speech synthesizer, cognitive engine, and macOS automation supervisor.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(2)

                            // Telemetry Tags
                            HStack(spacing: 8) {
                                telemetryPill(icon: "brain", text: LLMService.shared.activeModelName)
                                telemetryPill(icon: "mic.fill", text: "Apple Speech Engine")
                                telemetryPill(icon: "bolt.fill", text: "Zero-Latency Buffer")
                            }
                            .padding(.top, 4)
                        }

                        Spacer()
                    }
                }

                // 2x2 Metric Cards Grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    // Card 1: Runtime State
                    ControlCenterGlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(stateColor.opacity(0.2))
                                        .frame(width: 28, height: 28)

                                    Image(systemName: "waveform.circle.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(stateColor)
                                }

                                Spacer()

                                Text(appState.state == .idle ? "Standby" : "Active")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(stateColor.opacity(0.18))
                                    .foregroundColor(stateColor)
                                    .cornerRadius(4)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("ASSISTANT STATE")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                Text(stateText)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }
                    }

                    // Card 2: Global Trigger
                    ControlCenterGlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(ControlCenterTokens.Colors.accentEmerald.opacity(0.2))
                                        .frame(width: 28, height: 28)

                                    Image(systemName: "command.circle.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                                }

                                Spacer()

                                Text("System Intercept")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ControlCenterTokens.Colors.accentEmerald.opacity(0.18))
                                    .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                                    .cornerRadius(4)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("GLOBAL SHORTCUT")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))

                                HStack(spacing: 4) {
                                    ControlCenterKeycapView(appState.hotkeyDisplayString, fontSize: 13)
                                    Text("Press anywhere")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.45))
                                        .padding(.leading, 4)
                                }
                            }
                        }
                    }
                }

                // AI Engine Diagnostics Card
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentPurple.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 14))
                                    .foregroundColor(ControlCenterTokens.Colors.accentPurple)
                            }

                            Text("Active AI Engine Diagnostics")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            Text(LLMService.shared.activeProviderName)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ControlCenterTokens.Colors.accentIndigo.opacity(0.25))
                                .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                                .cornerRadius(6)
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.06))

                        VStack(spacing: 8) {
                            detailRow(label: "Model", value: LLMService.shared.activeModelName)
                            detailRow(label: "Credential Source", value: LLMService.shared.credentialSource)
                            detailRow(label: "API Endpoint", value: LLMService.shared.activeBaseURL)
                        }

                        // Interactive Ping Button
                        HStack {
                            Button {
                                runModelTest()
                            } label: {
                                HStack(spacing: 6) {
                                    if isTestingModel {
                                        ProgressView()
                                            .controlSize(.mini)
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "bolt.horizontal.fill")
                                            .font(.system(size: 11))
                                    }
                                    Text(isTestingModel ? "Testing Latency..." : "Test Connection")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ControlCenterTokens.Colors.accentIndigo)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(isTestingModel)

                            if let result = testResult {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(result.success ? ControlCenterTokens.Colors.accentEmerald : Color.red)
                                        .frame(width: 7, height: 7)
                                    Text(result.success ? "Connected in \(result.latencyMs)ms" : result.message)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(result.success ? ControlCenterTokens.Colors.accentEmerald : Color.red)
                                }
                                .padding(.leading, 8)
                            }

                            Spacer()
                        }
                    }
                }

                // Microphone & Audio Level Card
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentCyan.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "mic.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(ControlCenterTokens.Colors.accentCyan)
                            }

                            Text("Microphone & Audio Input")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            Text("Authorized")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.06))

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Real-Time Input Level:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text(String(format: "%.0f%%", appState.audioLevel * 100))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }

                            // 16-bar responsive equalizer visualizer
                            HStack {
                                ControlCenterEqualizerView(audioLevel: appState.audioLevel, barCount: 24, height: 26)
                                Spacer()
                            }
                            .padding(.vertical, 4)

                            HStack {
                                Text("Speech Recognizer:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Apple Speech (Speech.framework SFSpeechAudioBuffer)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    // MARK: - Helpers
    private func telemetryPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.6))
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.06))
        .cornerRadius(4)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var stateText: String {
        switch appState.state {
        case .idle: return "Ready / Idle"
        case .listening: return "Listening..."
        case .processing(let phase): return phase
        case .speaking: return "Speaking..."
        case .awaitingConfirmation: return "Awaiting Approval"
        case .error: return "Error"
        }
    }

    private var stateColor: Color {
        switch appState.state {
        case .idle: return ControlCenterTokens.Colors.accentEmerald
        case .listening: return Color.red
        case .processing: return ControlCenterTokens.Colors.accentCyan
        case .speaking: return ControlCenterTokens.Colors.accentPurple
        case .awaitingConfirmation: return ControlCenterTokens.Colors.accentAmber
        case .error: return Color.red
        }
    }

    private func runModelTest() {
        isTestingModel = true
        testResult = nil

        Task {
            let res = await LLMService.shared.pingModel()
            await MainActor.run {
                self.isTestingModel = false
                self.testResult = TestResult(
                    success: res.success,
                    latencyMs: res.latencyMs,
                    message: res.error ?? res.response
                )
            }
        }
    }
}
