import SwiftUI

/// Animated status badge showing a sub-agent's execution progress in the HUD.
public struct AgentStatusChip: View {
    public let agent: ActiveSubAgent
    @State private var isPulsing: Bool = false

    public init(agent: ActiveSubAgent) {
        self.agent = agent
    }

    private var statusColor: Color {
        switch agent.status {
        case .pending:
            return .gray
        case .running:
            return .yellow
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: agent.iconName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text(agent.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)

            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .opacity(agent.status == .running ? (isPulsing ? 0.3 : 1.0) : 1.0)
                .animation(
                    agent.status == .running ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                    value: isPulsing
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3.5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
        )
        .onAppear {
            if agent.status == .running {
                isPulsing = true
            }
        }
    }
}
