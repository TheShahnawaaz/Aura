import SwiftUI

/// Connectors and MCP tools configuration section.
public struct ConnectorsSettingsView: View {
    @AppStorage("gmailConnected") private var gmailConnected: Bool = false
    @AppStorage("notionConnected") private var notionConnected: Bool = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connectors & Tools")
                        .font(.title2.weight(.bold))
                    Text("Supercharge Aura with local macOS automations, cloud productivity tools, and Model Context Protocol (MCP).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 1. Native macOS System Agent
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("macOS System Automation", systemImage: "terminal.fill")
                            .font(.headline)
                        Spacer()
                        Text("Active & Ready")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }

                    Divider()

                    Text("Executes native macOS system commands via AppleScript and terminal sandboxing.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        featureBullet("Launch Applications (e.g. \"Open Safari\", \"Open Notes\")")
                        featureBullet("System Volume Controls (\"Volume up\", \"Mute\")")
                        featureBullet("Desktop Screenshot Capture (\"Take a screenshot\")")
                        featureBullet("File & Desktop Inspection (\"What's on my desktop\")")
                    }
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // 2. Gmail Connector
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Gmail Integration", systemImage: "envelope.fill")
                            .font(.headline)
                        Spacer()
                        Text(gmailConnected ? "Connected" : "Available")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background((gmailConnected ? Color.green : Color.secondary).opacity(0.15))
                            .foregroundColor(gmailConnected ? .green : .secondary)
                            .cornerRadius(4)
                    }

                    Divider()

                    Text("Draft emails, summarize your recent inbox, and search messages using OAuth2 authentication.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(gmailConnected ? "Disconnect Account" : "Connect Google Account") {
                        gmailConnected.toggle()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // 3. Notion Connector
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Notion Workspace", systemImage: "doc.text.fill")
                            .font(.headline)
                        Spacer()
                        Text(notionConnected ? "Connected" : "Available")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background((notionConnected ? Color.green : Color.secondary).opacity(0.15))
                            .foregroundColor(notionConnected ? .green : .secondary)
                            .cornerRadius(4)
                    }

                    Divider()

                    Text("Query project databases, create meeting notes, and retrieve knowledge base pages.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(notionConnected ? "Disconnect Notion" : "Connect Notion Workspace") {
                        notionConnected.toggle()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // 4. Model Context Protocol (MCP)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Model Context Protocol (MCP)", systemImage: "server.rack")
                            .font(.headline)
                        Spacer()
                        Text("Configurable")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.blue)
                    }

                    Divider()

                    Text("Connect custom MCP JSON-RPC servers (GitHub, SQLite, filesystem, browser tools) directly into the Multi-Agent Dispatcher.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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

    private func featureBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .padding(.top, 2)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}
