import SwiftUI

/// Appearance and HUD customization section styled with obsidian liquid-glass design.
public struct AppearanceSettingsView: View {
    @ObservedObject public var appState: AppState
    @StateObject private var geometry = NotchGeometry()

    @AppStorage("enableAmbientGlow") private var enableAmbientGlow: Bool = true
    @AppStorage("enableHapticFeedback") private var enableHapticFeedback: Bool = true
    @AppStorage("enableLiveDockIcon") private var enableLiveDockIcon: Bool = true

    public init(appState: AppState = .shared) {
        self.appState = appState
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Appearance & Display")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Hardware notch calibration, glassmorphism material finish, and ambient lighting.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                // 1. Hardware Calibration & Positioning Card
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentIndigo.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "macbook.gen2")
                                    .font(.system(size: 13))
                                    .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                            }

                            Text("MacBook Notch Calibration")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()

                            Text(geometry.hasNotch ? "Hardware Notch Detected" : "Floating Pill Mode")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(ControlCenterTokens.Colors.accentIndigo.opacity(0.25))
                                .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                                .cornerRadius(4)
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.06))

                        VStack(spacing: 8) {
                            metricRow(label: "Screen Dimensions", value: "\(Int(geometry.screenFrame.width)) × \(Int(geometry.screenFrame.height)) pt")
                            metricRow(label: "Physical Notch Width", value: "\(Int(geometry.notchWidth)) pt")
                            metricRow(label: "Hardware Notch Center X", value: String(format: "%.1f pt", geometry.notchCenterX))
                            metricRow(label: "HUD Constant Cap Width", value: "\(Int(geometry.closedWidth)) pt")
                            metricRow(label: "Alignment Status", value: "Subpixel Centered & Bezel-Flush")
                        }
                    }
                }

                // 2. Visual Effects & Glassmorphism
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentPurple.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 13))
                                    .foregroundColor(ControlCenterTokens.Colors.accentPurple)
                            }

                            Text("Visual Polish & Effects")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.06))

                        Toggle("Enable ambient breathing glow on status indicator dot", isOn: $enableAmbientGlow)
                            .toggleStyle(.switch)
                            .foregroundColor(.white.opacity(0.9))

                        Toggle("Enable tactile sound / haptic feedback on submission", isOn: $enableHapticFeedback)
                            .toggleStyle(.switch)
                            .foregroundColor(.white.opacity(0.9))

                        HStack {
                            Text("HUD Backdrop Finish:")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("Apple Glassmorphism (.ultraThinMaterial + 88% Jet Black)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }

                // 3. Living Aurora Orb & Dock Icon Card
                ControlCenterGlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(ControlCenterTokens.Colors.accentCyan.opacity(0.2))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "app.dashed")
                                    .font(.system(size: 13))
                                    .foregroundColor(ControlCenterTokens.Colors.accentCyan)
                            }

                            Text("Living Aurora Orb & Dock Icon")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Spacer()
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.06))

                        Toggle("Enable live interactive animation in macOS Dock icon", isOn: $enableLiveDockIcon)
                            .toggleStyle(.switch)
                            .foregroundColor(.white.opacity(0.9))
                            .onChange(of: enableLiveDockIcon) { _, _ in
                                if let delegate = NSApplication.shared.delegate as? AppDelegate {
                                    delegate.refreshDockTile()
                                }
                            }

                        HStack(spacing: 16) {
                            LivingAuroraOrbView(appState: appState, size: 48, showSquircleBackground: false)
                                .shadow(color: ControlCenterTokens.Colors.accentIndigo.opacity(0.3), radius: 10)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Tactile Iridescent Glass Sphere")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Real-time voice-reactive fluid animations across Idle, Listening, Processing, and Speaking states.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
