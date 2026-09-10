import SwiftUI

/// Custom obsidian liquid-glass navigation row for the Control Center sidebar.
/// Supports both full-width expanded layout and compact icon-only dock rail mode.
public struct ControlCenterSidebarRow: View {
    public let item: SidebarItem
    public let isSelected: Bool
    public let isCollapsed: Bool
    public let onSelect: () -> Void

    @State private var isHovered: Bool = false

    public init(
        item: SidebarItem,
        isSelected: Bool,
        isCollapsed: Bool = false,
        onSelect: @escaping () -> Void
    ) {
        self.item = item
        self.isSelected = isSelected
        self.isCollapsed = isCollapsed
        self.onSelect = onSelect
    }

    public var body: some View {
        Button {
            onSelect()
        } label: {
            if isCollapsed {
                collapsedView
            } else {
                expandedView
            }
        }
        .buttonStyle(.plain)
        .help(item.title)
        .onHover { hovering in
            withAnimation(ControlCenterTokens.Motion.snappy) {
                isHovered = hovering
            }
        }
    }

    // MARK: - Expanded Layout
    private var expandedView: some View {
        HStack(spacing: 10) {
            // Icon squircle badge
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(item.iconColor.opacity(isSelected ? 0.25 : (isHovered ? 0.16 : 0.08)))
                    .frame(width: 26, height: 26)

                Image(systemName: item.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? item.iconColor : (isHovered ? .white : .white.opacity(0.7)))
            }

            // Title
            Text(item.title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : (isHovered ? .white.opacity(0.9) : .white.opacity(0.65)))

            Spacer()

            // Subtle active indicator pill
            if isSelected {
                Circle()
                    .fill(item.iconColor)
                    .frame(width: 5, height: 5)
                    .shadow(color: item.iconColor.opacity(0.8), radius: 3)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            if isSelected {
                ZStack {
                    RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.capsule, style: .continuous)
                        .fill(ControlCenterTokens.Gradients.activeCapsuleGlow(color: item.iconColor))

                    RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.capsule, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    item.iconColor.opacity(0.40),
                                    item.iconColor.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            } else if isHovered {
                RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.capsule, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Collapsed Layout (Icon-Only Mini Rail)
    private var collapsedView: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ControlCenterTokens.Gradients.activeCapsuleGlow(color: item.iconColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        item.iconColor.opacity(0.50),
                                        item.iconColor.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            } else if isHovered {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            }

            Image(systemName: item.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? item.iconColor : (isHovered ? .white : .white.opacity(0.7)))
        }
        .frame(width: 38, height: 34)
        .contentShape(Rectangle())
    }
}
