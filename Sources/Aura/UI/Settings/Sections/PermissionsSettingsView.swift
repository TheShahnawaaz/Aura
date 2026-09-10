import SwiftUI

/// Dedicated permissions screen allowing users to view, test, trigger, and manage
/// all macOS system authorizations required by Aura, styled with obsidian liquid-glass.
public struct PermissionsSettingsView: View {
    @ObservedObject public var permissionManager: PermissionManager = .shared

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header

                heroStatusBanner

                VStack(spacing: 12) {
                    ForEach(PermissionType.allCases) { type in
                        permissionCard(for: type)
                    }
                }

                troubleshootingCallout
            }
            .padding(24)
        }
        .onAppear {
            permissionManager.refreshAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionManager.refreshAll()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Permissions Hub")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Aura uses native macOS APIs to automate apps, observe interfaces, and listen to voice commands.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Button {
                permissionManager.refreshAll()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                    Text("Refresh")
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Hero Status Banner
    private var heroStatusBanner: some View {
        ControlCenterGlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill((allGranted ? ControlCenterTokens.Colors.accentEmerald : ControlCenterTokens.Colors.accentAmber).opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: allGranted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.system(size: 22))
                        .foregroundColor(allGranted ? ControlCenterTokens.Colors.accentEmerald : ControlCenterTokens.Colors.accentAmber)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(allGranted ? "All Essential Permissions Granted" : "\(permissionManager.grantedCount) of \(PermissionType.allCases.count) Permissions Active")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    Text(allGranted ? "Aura has full access to automate your Mac, control UI, and process voice instructions." : "Some capabilities may be limited until missing permissions are granted.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                if !allGranted {
                    Button {
                        permissionManager.requestAll()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("Grant All")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ControlCenterTokens.Colors.accentPurple)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var allGranted: Bool {
        permissionManager.grantedCount == PermissionType.allCases.count
    }

    // MARK: - Permission Card
    private func permissionCard(for type: PermissionType) -> some View {
        let status = permissionManager.status(for: type)

        return ControlCenterGlassCard {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(iconColor(for: status).opacity(0.18))
                        .frame(width: 32, height: 32)

                    Image(systemName: type.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor(for: status))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(type.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        statusBadge(for: status)
                    }

                    Text(type.description)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HStack(spacing: 8) {
                    if status != .granted {
                        Button {
                            permissionManager.requestAccess(for: type)
                        } label: {
                            Text("Authorize")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(ControlCenterTokens.Colors.accentIndigo)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        permissionManager.openSettings(for: type)
                    } label: {
                        Text("System Settings")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func iconColor(for status: PermissionStatus) -> Color {
        switch status {
        case .granted: return ControlCenterTokens.Colors.accentEmerald
        case .notDetermined: return ControlCenterTokens.Colors.accentAmber
        case .denied: return Color.red
        }
    }

    private func statusBadge(for status: PermissionStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(iconColor(for: status))
                .frame(width: 5, height: 5)

            Text(status.rawValue)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(iconColor(for: status))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(iconColor(for: status).opacity(0.15))
        .cornerRadius(4)
    }

    // MARK: - Troubleshooting Callout
    private var troubleshootingCallout: some View {
        ControlCenterGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                        .font(.system(size: 13))
                    Text("Developer Tip: Refreshing Permissions After Rebuilding")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("If you rebuild Aura from source, macOS may consider the new binary signature untrusted even if the toggle switch is already 'ON' in System Settings. If an automation action fails, simply toggle the switch **OFF and back ON** in System Settings > Privacy & Security, or click 'Authorize' above.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
