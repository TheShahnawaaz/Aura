import SwiftUI
import OpenAgentSDK

/// Skills management view in Aura Control Center styled with obsidian liquid-glass design.
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
                        .foregroundColor(ControlCenterTokens.Colors.accentEmerald)
                    Text(toast)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(10)
                .background(ControlCenterTokens.Colors.accentEmerald.opacity(0.18))
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
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(activeCount) of \(allSkills.count) Active")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(ControlCenterTokens.Colors.accentIndigo.opacity(0.25))
                        .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                        .cornerRadius(4)
                }
                Text("Skills provide specialized prompt workflows and tool orchestration for high-level tasks.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    let folder = AuraSkillRegistry.shared.ensureSkillsFolderExists()
                    NSWorkspace.shared.open(URL(fileURLWithPath: folder))
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.badge.gearshape")
                        Text("Skills Folder")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white)
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)

                Button {
                    AuraSkillRegistry.shared.reloadSkills()
                    withAnimation {
                        reloadToast = "Skills reloaded from ~/.aura/skills"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { reloadToast = nil }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reload")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white)
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Skill Card
    private func skillCard(for skill: Skill) -> some View {
        let isEnabled = capabilityConfig.isSkillEnabled(skill.name)
        let isBuiltIn = ["mac_control", "developer_inspection", "productivity"].contains(skill.name)

        return ControlCenterGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill((isEnabled ? ControlCenterTokens.Colors.accentIndigo : Color.white).opacity(0.12))
                            .frame(width: 32, height: 32)

                        Image(systemName: iconForSkill(skill.name))
                            .font(.system(size: 14))
                            .foregroundColor(isEnabled ? ControlCenterTokens.Colors.accentIndigo : .white.opacity(0.5))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(skill.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)

                            Text(isBuiltIn ? "Built-in" : "Custom")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background((isBuiltIn ? ControlCenterTokens.Colors.accentPurple : ControlCenterTokens.Colors.accentCyan).opacity(0.2))
                                .foregroundColor(isBuiltIn ? ControlCenterTokens.Colors.accentPurple : ControlCenterTokens.Colors.accentCyan)
                                .cornerRadius(3)
                        }

                        Text(skill.description)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
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
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ControlCenterTokens.Colors.accentIndigo)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(isEnabled ? "Active in Runtime" : "Disabled")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isEnabled ? ControlCenterTokens.Colors.accentEmerald : .white.opacity(0.4))
                }
            }
        }
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button("Done") {
                    inspectedSkill = nil
                }
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(ControlCenterTokens.Colors.accentIndigo)
                .foregroundColor(.white)
                .cornerRadius(6)
                .buttonStyle(.plain)
            }

            Text(skill.description)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.65))

            Divider()
                .overlay(Color.white.opacity(0.06))

            Text("System Prompt & Instructions")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)

            ScrollView {
                Text(skill.promptTemplate)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ControlCenterTokens.Colors.sunkenSurface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .frame(maxHeight: 280)
        }
        .padding(20)
        .background(ControlCenterTokens.Colors.windowBackdrop)
        .frame(width: 520, height: 420)
    }
}

extension Skill: @retroactive Identifiable {
    public var id: String { name }
}
