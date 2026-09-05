import AppKit
import SwiftUI

/// Micro copy action button with haptic spring feedback and auto-resetting checkmark indicator.
public struct HUDCopyButton: View {
    public let textToCopy: String
    @State private var copied: Bool = false

    public init(text: String) {
        self.textToCopy = text
    }

    public var body: some View {
        Button {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(textToCopy, forType: .string)

            withAnimation(HUDDesignTokens.Springs.snappy) {
                copied = true
            }

            Task {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                await MainActor.run {
                    withAnimation(HUDDesignTokens.Springs.snappy) {
                        copied = false
                    }
                }
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(copied ? HUDDesignTokens.Colors.emeraldSuccess : Color.white.opacity(0.45))

                if copied {
                    Text("Copied")
                        .font(.system(size: 8.5, weight: .medium, design: .rounded))
                        .foregroundColor(HUDDesignTokens.Colors.emeraldSuccess)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2.5)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(copied ? Color.green.opacity(0.12) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(copied ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help("Copy to clipboard")
    }
}
