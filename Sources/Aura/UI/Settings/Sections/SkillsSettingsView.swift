import SwiftUI
import OpenAgentSDK

/// Skills management view in Aura Control Center.
public struct SkillsSettingsView: View {
    @ObservedObject private var capabilityConfig = CapabilityConfigManager.shared
    @State private var inspectedSkill: Skill? = nil
    @State private var reloadToast: String? = nil

    public init() {}

    private var allSkills: [Skill] {
        AuraSkillRegistry.shared.registry.allSkills
    }

    private var activeCount: Int {
        allSkills.filter { capabilityConfig.isSkillEnabled($0.name) }.count
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerBar

            if let toast = reloadToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(toast)
                        .font(.caption.weight(.medium))
                    Spacer()
                }
                .padding(10)
                .background(Color.green.opacity(0.12))
                .cornerRadius(8)
                .transition(.opacity)
            }

            VStack(spacing: 12) {
                ForEach(allSkills, id: \.name) { skill in
                    skillCard(for: skill)
                }
            }
        }
        .sheet(item: $inspectedSkill) { skill in
            skillInspectorSheet(skill: skill)
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Domain Skills")
                        .font(.title3.weight(.bold))
                    Text("\(activeCount) of \(allSkills.count) Active")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                Text("Skills provide specialized prompt workflows and tool orchestration for high-level tasks.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    let folder = AuraSkillRegistry.shared.ensureSkillsFolderExists()
                    NSWorkspace.shared.open(URL(fileURLWithPath: folder))
                } label: {
                    Label("Skills Folder", systemImage: "folder.badge.gearshape")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    AuraSkillRegistry.shared.reloadSkills()
                    withAnimation {
                        reloadToast = "Skills reloaded from ~/.aura/skills"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { reloadToast = nil }
                    }
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Skill Card
    private func skillCard(for skill: Skill) -> some View {
        let isEnabled = capabilityConfig.isSkillEnabled(skill.name)
        let isBuiltIn = ["mac_control", "developer_inspection", "productivity"].contains(skill.name)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: iconForSkill(skill.name))
                    .font(.title3)
                    .foregroundColor(isEnabled ? .blue : .secondary)
                    .frame(width: 32, height: 32)
                    .background((isEnabled ? Color.blue : Color.secondary).opacity(0.12))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(skill.name)
                            .font(.subheadline.weight(.semibold))
                        Text(isBuiltIn ? "Built-in" : "Custom")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background((isBuiltIn ? Color.purple : Color.teal).opacity(0.15))
                            .foregroundColor(isBuiltIn ? .purple : .teal)
                            .cornerRadius(4)
                    }

                    Text(skill.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { capabilityConfig.isSkillEnabled(skill.name) },
                    set: { capabilityConfig.setSkillEnabled(skill.name, isEnabled: $0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }

            HStack {
                Button {
                    inspectedSkill = skill
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Inspect Prompt & Rules")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(isEnabled ? "Active in Runtime" : "Disabled")
                    .font(.caption2)
                    .foregroundColor(isEnabled ? .green : .secondary)
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isEnabled ? Color.blue.opacity(0.2) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func iconForSkill(_ name: String) -> String {
        switch name {
        case "mac_control": return "macwindow.on.rectangle"
        case "developer_inspection": return "terminal.fill"
        case "productivity": return "checklist"
        default: return "sparkles"
        }
    }

    // MARK: - Prompt Inspector Sheet
    private func skillInspectorSheet(skill: Skill) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(skill.name, systemImage: iconForSkill(skill.name))
                    .font(.title3.weight(.bold))
                Spacer()
                Button("Done") {
                    inspectedSkill = nil
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Text(skill.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            Text("System Prompt & Instructions")
                .font(.headline)

            ScrollView {
                Text(skill.promptTemplate)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 280)
        }
        .padding(20)
        .frame(width: 520, height: 420)
    }
}

extension Skill: @retroactive Identifiable {
    public var id: String { name }
}
