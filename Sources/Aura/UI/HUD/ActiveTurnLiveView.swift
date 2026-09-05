import SwiftUI

/// Elevated, real-time live content card displayed in the Notch HUD while an active
/// turn is executing (Listening, Processing, Speaking, Awaiting Confirmation, or Error).
public struct ActiveTurnLiveView: View {
    @ObservedObject public var appState: AppState
    public var orbNamespace: Namespace.ID
    public var isOrbDownInMessageArea: Bool

    public init(
        appState: AppState,
        orbNamespace: Namespace.ID,
        isOrbDownInMessageArea: Bool
    ) {
        self.appState = appState
        self.orbNamespace = orbNamespace
        self.isOrbDownInMessageArea = isOrbDownInMessageArea
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Left Living Aurora Orb (Transitions smoothly between Cap Bar and Content Area)
            if isOrbDownInMessageArea {
                LivingAuroraOrbView(appState: appState, size: 40, showSquircleBackground: false)
                    .matchedGeometryEffect(id: "auraSingleLivingOrb", in: orbNamespace)
                    .frame(width: 40, height: 40)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Live Content Box
                liveContentBox
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Consistent Footer Row
                footerRow
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Live Content Box
    @ViewBuilder
    private var liveContentBox: some View {
        switch appState.state {
        case .listening:
            listeningCard

        case .processing(let phase):
            processingCard(phase: phase)

        case .speaking(let text):
            speakingCard(text: text)

        case .awaitingConfirmation(let request):
            confirmationCard(request: request)

        case .error(let message):
            errorCard(message: message)

        default:
            EmptyView()
        }
    }

    // MARK: - 1. Listening Card
    private var listeningCard: some View {
        HUDGlassCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(HUDDesignTokens.Colors.listeningCyan)
                            .frame(width: 5, height: 5)
                            .shadow(color: HUDDesignTokens.Colors.listeningCyan, radius: 3)
                        Text("LISTENING")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(HUDDesignTokens.Colors.listeningCyan)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(HUDDesignTokens.Colors.listeningCyan.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()
                }

                ScrollView(.vertical, showsIndicators: false) {
                    if appState.partialTranscript.isEmpty {
                        Text("Speak naturally...")
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.40))
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(appState.partialTranscript)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .animation(.easeInOut(duration: 0.12), value: appState.partialTranscript)
                    }
                }
            }
        }
    }

    // MARK: - 2. Processing Card
    private func processingCard(phase: String) -> some View {
        HUDGlassCard {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(Color(red: 0.75, green: 0.45, blue: 1.0))
                        Text("REASONING")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(Color(red: 0.75, green: 0.45, blue: 1.0))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color(red: 0.65, green: 0.25, blue: 0.95).opacity(0.15))
                    .clipShape(Capsule())

                    Spacer()
                }

                AuroraShimmerBeam()

                VStack(alignment: .leading, spacing: 2) {
                    Text(phase)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(2)

                    Text("Aura is synthesizing context and orchestrating tools...")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - 3. Speaking Card
    private func speakingCard(text: String) -> some View {
        HUDGlassCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(HUDDesignTokens.Colors.speakingCoral)
                        Text("AURA")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(HUDDesignTokens.Colors.speakingCoral)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(HUDDesignTokens.Colors.speakingCoral.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    HUDCopyButton(text: text)
                }

                ScrollView(.vertical, showsIndicators: false) {
                    Text(text)
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundColor(.white.opacity(0.93))
                        .lineSpacing(3.5)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - 4. Confirmation Card
    private func confirmationCard(request: ActionConfirmationRequest) -> some View {
        HUDGlassCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(HUDDesignTokens.Colors.actionAmber)
                        .font(.system(size: 11))
                    Text("APPROVAL REQUIRED")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(HUDDesignTokens.Colors.actionAmber)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(HUDDesignTokens.Colors.actionAmber.opacity(0.12))
                .clipShape(Capsule())

                Text(request.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(request.description)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.70))
                    .lineLimit(1)

                Text(request.commandOrAction)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.white.opacity(0.92))
                    .padding(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.45))
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                    .lineLimit(2)
            }
        }
    }

    // MARK: - 5. Error Card
    private func errorCard(message: String) -> some View {
        HUDGlassCard {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(HUDDesignTokens.Colors.errorRed)
                Text(message)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Pinned Footer Row
    private var footerRow: some View {
        HStack(alignment: .center) {
            // Left Status / Hint
            Group {
                switch appState.state {
                case .listening:
                    HStack(spacing: 5) {
                        Text("Press")
                            .foregroundColor(.white.opacity(0.45))
                        MiniKeycapView(appState.hotkeyDisplayString)
                        Text("again to send")
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .font(.system(size: 9.5, design: .rounded))

                case .processing:
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(red: 0.70, green: 0.40, blue: 1.0))
                            .frame(width: 4, height: 4)
                        Text("Orchestrating...")
                            .font(.system(size: 9.5, design: .rounded))
                            .foregroundColor(.white.opacity(0.50))
                    }

                case .speaking:
                    HStack(spacing: 4) {
                        Circle()
                            .fill(HUDDesignTokens.Colors.speakingCoral)
                            .frame(width: 4, height: 4)
                        Text("Speaking response...")
                            .font(.system(size: 9.5, design: .rounded))
                            .foregroundColor(.white.opacity(0.50))
                    }

                case .awaitingConfirmation(let request):
                    HStack(spacing: 8) {
                        Button {
                            ApprovalCoordinator.shared.approve(id: request.id)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark")
                                Text("Approve")
                            }
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(HUDDesignTokens.Gradients.approveButton)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            ApprovalCoordinator.shared.deny(id: request.id)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "xmark")
                                Text("Deny")
                            }
                            .font(.system(size: 9.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.90))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                default:
                    EmptyView()
                }
            }

            Spacer()

            // Right Action Hints: esc to cancel & Open Chat
            HStack(spacing: 8) {
                Button {
                    if let delegate = AppDelegate.shared {
                        delegate.cancelOrDiscardActiveEvent()
                    } else {
                        appState.resetToIdle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        MiniKeycapView("⎋ esc")
                        Text("to cancel")
                            .font(.system(size: 9, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.38))
                    }
                }
                .buttonStyle(.plain)
                .help("Discard current session (or press Esc)")

                Text("•")
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.18))

                Button {
                    SettingsWindowController.shared.showChat()
                    withAnimation(HUDDesignTokens.Springs.snappy) {
                        appState.resetToIdle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 8))
                        Text("Open Chat")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Open full chat thread in Aura Control Center")
            }
        }
        .frame(height: 18)
    }
}
