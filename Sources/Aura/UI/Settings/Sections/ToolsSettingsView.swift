import SwiftUI

/// A small, actionable overview of Aura's built-in tools.
public struct ToolsSettingsView: View {
    @State private var terminalEnabled = true
    @State private var automationsEnabled = true
    @State private var connectorEnabled = false
    @State private var lastAction = "Ready for a task"

    public init() {}

    public var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    HStack(alignment: .top, spacing: 16) {
                        toolCard(
                            icon: "terminal.fill",
                            tint: .blue,
                            title: "Terminal",
                            detail: "Run approved commands in your login shell.",
                            status: terminalEnabled ? "Available" : "Paused",
                            isEnabled: $terminalEnabled,
                            action: "Open terminal",
                            actionHandler: { lastAction = "Terminal session opened" }
                        )

                        toolCard(
                            icon: "sparkles",
                            tint: .purple,
                            title: "Automations",
                            detail: "Turn repeatable steps into quick actions.",
                            status: automationsEnabled ? "2 ready" : "Paused",
                            isEnabled: $automationsEnabled,
                            action: "View routines",
                            actionHandler: { lastAction = "Showing your routines" }
                        )

                        toolCard(
                            icon: "point.3.connected.trianglepath.dotted",
                            tint: .cyan,
                            title: "Connectors",
                            detail: "Bring your workspace apps into Aura.",
                            status: connectorEnabled ? "Connected" : "Not connected",
                            isEnabled: $connectorEnabled,
                            action: "Manage apps",
                            actionHandler: { lastAction = "Connector setup is ready" }
                        )
                    }

                    HStack(spacing: 9) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text(lastAction)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
                .padding(32)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tools")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("Three ways Aura can help you get work moving.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private func toolCard(
        icon: String,
        tint: Color,
        title: String,
        detail: String,
        status: String,
        isEnabled: Binding<Bool>,
        action: String,
        actionHandler: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 46, height: 46)
                    .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Spacer()
                Toggle("", isOn: isEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.title3.weight(.bold))
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            HStack {
                Label(status, systemImage: isEnabled.wrappedValue ? "checkmark.circle.fill" : "pause.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isEnabled.wrappedValue ? .green : .secondary)
                Spacer()
                Button(action, action: actionHandler)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!isEnabled.wrappedValue)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 244, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        }
        .onHover { hovering in
            NSCursor.pointingHand.set()
        }
    }
}
