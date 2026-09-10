import SwiftUI

/// Floating obsidian liquid-glass capsule tab bar with sliding matched geometry highlight,
/// specular edge gradient, and Framer-Motion-calibrated spring physics.
public struct ControlCenterLiquidTabBar<Tab: Hashable & Identifiable>: View {
    @Binding public var selectedTab: Tab
    public let tabs: [Tab]
    public let titleForTab: (Tab) -> String
    public let iconForTab: (Tab) -> String

    @Namespace private var tabNamespace
    @State private var hoveredTab: Tab? = nil

    public init(
        selectedTab: Binding<Tab>,
        tabs: [Tab],
        titleForTab: @escaping (Tab) -> String,
        iconForTab: @escaping (Tab) -> String
    ) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        self.titleForTab = titleForTab
        self.iconForTab = iconForTab
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                tabButton(for: tab)
            }
        }
        .padding(4)
        .background {
            ZStack {
                // Frosted obsidian glass backing
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(ControlCenterTokens.Colors.sunkenSurface)

                // Specular edge border
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(ControlCenterTokens.Gradients.specularBorder, lineWidth: 1)
            }
        }
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 2)
    }

    private func tabButton(for tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        let isHovered = hoveredTab == tab

        return Button {
            withAnimation(ControlCenterTokens.Motion.snappy) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: iconForTab(tab))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? ControlCenterTokens.Colors.accentIndigo : (isHovered ? .white : .white.opacity(0.6)))

                Text(titleForTab(tab))
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : (isHovered ? .white.opacity(0.9) : .white.opacity(0.65)))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ControlCenterTokens.Colors.accentIndigo.opacity(0.32),
                                        ControlCenterTokens.Colors.accentIndigo.opacity(0.16)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .matchedGeometryEffect(id: "activeTabPill", in: tabNamespace)

                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        ControlCenterTokens.Colors.accentIndigo.opacity(0.5),
                                        Color.white.opacity(0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .matchedGeometryEffect(id: "activeTabBorder", in: tabNamespace)
                    }
                    .shadow(color: ControlCenterTokens.Colors.accentIndigo.opacity(0.25), radius: 4, y: 1)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(ControlCenterTokens.Motion.snappy) {
                if hovering {
                    hoveredTab = tab
                } else if hoveredTab == tab {
                    hoveredTab = nil
                }
            }
        }
    }
}
