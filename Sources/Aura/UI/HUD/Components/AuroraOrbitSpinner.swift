import SwiftUI

/// Compact spinning orbit loader for notch ear and compact status rows.
public struct AuroraOrbitSpinner: View {
    @State private var isRotating: Bool = false

    public init() {}

    public var body: some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                    .frame(width: 10, height: 10)

                Circle()
                    .trim(from: 0.0, to: 0.65)
                    .stroke(
                        LinearGradient(
                            colors: [
                                HUDDesignTokens.Colors.processingViolet,
                                HUDDesignTokens.Colors.processingCyan
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 1.75, lineCap: .round)
                    )
                    .frame(width: 10, height: 10)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
            }
            .onAppear {
                withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                    isRotating = true
                }
            }

            Text("Thinking")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.75, green: 0.60, blue: 1.0))
        }
    }
}
