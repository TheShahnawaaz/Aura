import SwiftUI

/// Dedicated permissions screen allowing users to view, test, trigger, and manage
/// all macOS system authorizations required by Aura.
public struct PermissionsSettingsView: View {
    @ObservedObject public var permissionManager: PermissionManager = .shared

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                heroStatusBanner

                VStack(spacing: 14) {
                    ForEach(PermissionType.allCases) { type in
                        permissionCard(for: type)
                    }
                }

                troubleshootingCallout
            }
            .padding(28)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            permissionManager.refreshAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionManager.refreshAll()
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Permissions Hub")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Spacer()
                Button {
                    permissionManager.refreshAll()
                } label: {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }

            Text("Aura uses native macOS APIs to automate apps, observe interfaces, and listen to voice commands. Grant authorizations below for full functionality.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Hero Status Banner
    private var heroStatusBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(allGranted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: allGranted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(allGranted ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(allGranted ? "All Essential Permissions Granted" : "\(permissionManager.grantedCount) of \(PermissionType.allCases.count) Permissions Active")
                    .font(.headline)

                Text(allGranted ? "Aura has full access to automate your Mac, control UI, and process voice instructions." : "Some capabilities may be limited until missing permissions are granted.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !allGranted {
                Button {
                    permissionManager.requestAll()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Trigger All Permissions")
                    }
                    .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(allGranted ? Color.green.opacity(0.2) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var allGranted: Bool {
        permissionManager.grantedCount == PermissionType.allCases.count
    }

    // MARK: - Permission Card
    private func permissionCard(for type: PermissionType) -> some View {
        let status = permissionManager.status(for: type)

        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: type.iconName)
                .font(.system(size: 20))
                .foregroundColor(iconColor(for: status))
                .frame(width: 36, height: 36)
                .background(iconColor(for: status).opacity(0.12))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(type.rawValue)
                        .font(.headline)

                    statusBadge(for: status)
                }

                Text(type.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            HStack(spacing: 8) {
                if status != .granted {
                    Button("Request Access") {
                        permissionManager.requestAccess(for: type)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Button("Open Settings") {
                    permissionManager.openSettings(for: type)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func iconColor(for status: PermissionStatus) -> Color {
        switch status {
        case .granted: return .green
        case .notDetermined: return .orange
        case .denied: return .red
        }
    }

    private func statusBadge(for status: PermissionStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(iconColor(for: status))
                .frame(width: 6, height: 6)

            Text(status.rawValue)
                .font(.caption2.weight(.semibold))
                .foregroundColor(iconColor(for: status))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(iconColor(for: status).opacity(0.12))
        .cornerRadius(4)
    }

    // MARK: - Troubleshooting Callout
    private var troubleshootingCallout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Developer Tip: Refreshing Permissions After Rebuilding")
                    .font(.subheadline.weight(.semibold))
            }

            Text("If you rebuild Aura from source, macOS may consider the new binary signature untrusted even if the toggle switch is already 'ON' in System Settings. If an automation action fails, simply toggle the switch **OFF and back ON** in System Settings > Privacy & Security, or click 'Request Access' above.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.blue.opacity(0.06))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
    }
}
