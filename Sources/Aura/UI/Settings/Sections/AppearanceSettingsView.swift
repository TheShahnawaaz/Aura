import SwiftUI

/// Appearance and HUD customization section.
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Appearance & Display")
                        .font(.title2.weight(.bold))
                    Text("Hardware notch calibration, glassmorphism material finish, and ambient lighting.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 1. Hardware Calibration & Positioning Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("MacBook Notch Calibration", systemImage: "macbook.gen2")
                            .font(.headline)
                        Spacer()
                        Text(geometry.hasNotch ? "Hardware Notch Detected" : "Floating Pill Mode")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }

                    Divider()

                    VStack(spacing: 8) {
                        metricRow(label: "Screen Dimensions", value: "\(Int(geometry.screenFrame.width)) × \(Int(geometry.screenFrame.height)) pt")
                        metricRow(label: "Physical Notch Width", value: "\(Int(geometry.notchWidth)) pt")
                        metricRow(label: "Hardware Notch Center X", value: String(format: "%.1f pt", geometry.notchCenterX))
                        metricRow(label: "HUD Constant Cap Width", value: "\(Int(geometry.closedWidth)) pt")
                        metricRow(label: "Alignment Status", value: "Subpixel Centered & Bezel-Flush")
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // 2. Visual Effects & Glassmorphism
                VStack(alignment: .leading, spacing: 14) {
                    Label("Visual Polish & Effects", systemImage: "sparkles")
                        .font(.headline)

                    Divider()

                    Toggle("Enable ambient breathing glow on status indicator dot", isOn: $enableAmbientGlow)
                        .toggleStyle(.switch)

                    Toggle("Enable tactile sound / haptic feedback on submission", isOn: $enableHapticFeedback)
                        .toggleStyle(.switch)

                    HStack {
                        Text("HUD Backdrop Finish:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Apple Glassmorphism (.ultraThinMaterial + 88% Jet Black)")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // 3. Living Aurora Orb & Dock Icon Card
                VStack(alignment: .leading, spacing: 14) {
                    Label("Living Aurora Orb & Dock Icon", systemImage: "sparkles")
                        .font(.headline)

                    Divider()

                    Toggle("Enable live interactive animation in macOS Dock icon", isOn: $enableLiveDockIcon)
                        .toggleStyle(.switch)
                        .onChange(of: enableLiveDockIcon) { _, _ in
                            if let delegate = NSApplication.shared.delegate as? AppDelegate {
                                delegate.refreshDockTile()
                            }
                        }

                    HStack(spacing: 16) {
                        LivingAuroraOrbView(appState: appState, size: 52, showSquircleBackground: true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tactile Iridescent Glass Sphere")
                                .font(.subheadline.weight(.semibold))
                            Text("Real-time voice-reactive fluid animations across Idle, Listening, Processing, and Speaking states.")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
            }
            .padding(24)
        }
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundColor(.primary)
        }
    }
}
