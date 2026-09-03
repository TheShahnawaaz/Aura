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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Section Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Overview")
                        .font(.title2.weight(.bold))
                    Text("Live health metrics, active AI engine status, and diagnostic controls.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Hero Card with Living Aurora Orb
                HStack(spacing: 18) {
                    LivingAuroraOrbView(appState: appState, size: 56, showSquircleBackground: true)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Aura Core")
                                .font(.headline)
                            Text(stateText.uppercased())
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(stateColor.opacity(0.18))
                                .foregroundColor(stateColor)
                                .cornerRadius(4)
                        }
                        Text("Tactile living aurora glass orb with active real-time voice, reasoning, and speech synthesis.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // 1. Assistant Status Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statusCard(
                        title: "Assistant State",
                        value: stateText,
                        icon: "waveform.circle.fill",
                        iconColor: stateColor,
                        badge: appState.state == .idle ? "Standby" : "Active"
                    )

                    statusCard(
                        title: "Global Trigger",
                        value: appState.hotkeyDisplayString,
                        icon: "command.circle.fill",
                        iconColor: .green,
                        badge: "Registered"
                    )
                }

                // 2. Active AI Model & Connection Test Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Active AI Engine", systemImage: "brain.head.profile")
                            .font(.headline)
                        Spacer()
                        Text(LLMService.shared.activeProviderName)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }

                    Divider()

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
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "bolt.horizontal.fill")
                                }
                                Text(isTestingModel ? "Testing Latency..." : "Test Connection")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(isTestingModel)

                        if let result = testResult {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(result.success ? Color.green : Color.red)
                                    .frame(width: 7, height: 7)
                                Text(result.success ? "Connected in \(result.latencyMs)ms" : result.message)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(result.success ? .green : .red)
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

                // 3. Live Microphone Health
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Microphone & Audio Input", systemImage: "mic.fill")
                            .font(.headline)
                        Spacer()
                        Text("Authorized")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.green)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Real-Time Input Level:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f%%", appState.audioLevel * 100))
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundColor(.secondary)
                        }

                        // Audio Level Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.08))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan, .green],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(8, geo.size.width * CGFloat(min(1.0, appState.audioLevel * 2.5))))
                                    .animation(.interactiveSpring(response: 0.1, dampingFraction: 0.7), value: appState.audioLevel)
                            }
                        }
                        .frame(height: 10)

                        HStack {
                            Text("Speech Recognizer:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Apple Speech (Speech.framework SFSpeechAudioBuffer)")
                                .font(.caption.weight(.medium))
                        }
                        .padding(.top, 4)
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

    // MARK: - Helper Views
    private func statusCard(title: String, value: String, icon: String, iconColor: Color, badge: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                Spacer()
                Text(badge)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(iconColor.opacity(0.15))
                    .foregroundColor(iconColor)
                    .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
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
        case .idle: return .green
        case .listening: return .red
        case .processing: return .cyan
        case .speaking: return .purple
        case .awaitingConfirmation: return .orange
        case .error: return .red
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
