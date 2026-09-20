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
        HStack(spacing: 9) {
            // Icon squircle badge with hierarchical SF Symbol
            ZStack {
                RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.keycap, style: .continuous)
                    .fill(
                        isSelected
                            ? item.iconColor.opacity(0.20)
                            : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
                    )
                    .frame(width: 26, height: 26)
                    .overlay(
                        RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.keycap, style: .continuous)
                            .strokeBorder(
                                isSelected
                                    ? item.iconColor.opacity(0.35)
                                    : (isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.03)),
                                lineWidth: ControlCenterTokens.Stroke.hairline
                            )
                    )

                Image(systemName: item.iconName)
                    .font(.system(size: 12.5, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(isSelected ? item.iconColor : (isHovered ? .white : .white.opacity(0.70)))
            }

            // Title and description
            Text(item.title)
                .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : (isHovered ? .white.opacity(0.92) : .white.opacity(0.68)))
                .lineLimit(1)

            Spacer(minLength: 4)

            // Trailing keycap hint on hover or when selected
            if isHovered || isSelected {
                Text(item.shortcutString)
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? item.iconColor : .white.opacity(0.40))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .fill(isSelected ? item.iconColor.opacity(0.16) : Color.white.opacity(0.06))
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.capsule, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                item.iconColor.opacity(0.18),
                                item.iconColor.opacity(0.06)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
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
                                lineWidth: ControlCenterTokens.Stroke.hairline
                            )
                    )
            } else if isHovered {
                RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.capsule, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.capsule, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.04), lineWidth: ControlCenterTokens.Stroke.hairline)
                    )
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Collapsed Layout (Icon-Only Mini Rail)
    private var collapsedView: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.innerCard, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                item.iconColor.opacity(0.22),
                                item.iconColor.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.innerCard, style: .continuous)
                            .strokeBorder(
                                item.iconColor.opacity(0.40),
                                lineWidth: ControlCenterTokens.Stroke.hairline
                            )
                    )
            } else if isHovered {
                RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.innerCard, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: ControlCenterTokens.Radii.innerCard, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.05), lineWidth: ControlCenterTokens.Stroke.hairline)
                    )
            }

            Image(systemName: item.iconName)
                .font(.system(size: 13.5, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(isSelected ? item.iconColor : (isHovered ? .white : .white.opacity(0.70)))
        }
        .frame(width: 36, height: 32)
        .contentShape(Rectangle())
    }
}
