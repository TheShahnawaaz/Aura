import AppKit
import ImageIO
import SwiftUI

/// High-performance memory cache for downsampled tool image thumbnails.
@MainActor
public final class ImageThumbnailCache {
    public static let shared = ImageThumbnailCache()

    private let cache = NSCache<NSString, CachedThumbnail>()

    private final class CachedThumbnail: NSObject {
        let image: NSImage
        let originalWidth: Int
        let originalHeight: Int

        init(image: NSImage, originalWidth: Int, originalHeight: Int) {
            self.image = image
            self.originalWidth = originalWidth
            self.originalHeight = originalHeight
        }
    }

    private init() {
        cache.countLimit = 80
        cache.totalCostLimit = 60 * 1024 * 1024 // 60 MB memory cap
    }

    public func get(path: String) -> (image: NSImage, width: Int, height: Int)? {
        guard let item = cache.object(forKey: path as NSString) else { return nil }
        return (item.image, item.originalWidth, item.originalHeight)
    }

    public func load(path: String, maxDimension: CGFloat = 720) async -> (image: NSImage, width: Int, height: Int)? {
        if let existing = get(path: path) {
            return existing
        }

        let url = URL(fileURLWithPath: path)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        // Extract real full-resolution dimensions without decoding full bitmap
        var origW = 0
        var origH = 0
        if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            origW = props[kCGImagePropertyPixelWidth] as? Int ?? 0
            origH = props[kCGImagePropertyPixelHeight] as? Int ?? 0
        }

        // Downsample directly into thumbnail buffer via ImageIO hardware decode
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension)
        ]

        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        if origW == 0 { origW = cgThumb.width }
        if origH == 0 { origH = cgThumb.height }

        let thumbImage = NSImage(cgImage: cgThumb, size: NSSize(width: cgThumb.width, height: cgThumb.height))
        let cached = CachedThumbnail(image: thumbImage, originalWidth: origW, originalHeight: origH)
        self.cache.setObject(cached, forKey: path as NSString)

        return (thumbImage, origW, origH)
    }
}

/// Standardized, consistent preview card for all image-related tools (view_image, take_screenshot).
/// Renders every image within an identical, predictable frame with asynchronous zero-lag loading.
public struct ToolCallImagePreviewView: View {
    public let imagePath: String

    @State private var thumbnail: NSImage?
    @State private var originalWidth: Int = 0
    @State private var originalHeight: Int = 0
    @State private var isLoading: Bool = true
    @State private var isHovered: Bool = false

    public init(imagePath: String) {
        self.imagePath = imagePath
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Standardized Image Container Frame (Identical footprint across all image tools)
            ZStack {
                // Sunken obsidian backdrop
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ControlCenterTokens.Colors.sunkenSurface)

                if let thumb = thumbnail {
                    // Ambient blurred back-glow for portrait/square images
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 360, maxHeight: 180)
                        .clipped()
                        .blur(radius: 24)
                        .opacity(0.28)

                    // Sharp centered fitted image
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 360, maxHeight: 180)
                        .cornerRadius(6)

                    // Hover Quick Action Overlay
                    if isHovered {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                            .overlay(
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("Click to open")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.black.opacity(0.65))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            )
                            .transition(.opacity)
                    }
                } else if isLoading {
                    // Shimmer loading placeholder
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.8)
                        Text("Loading visual preview...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    // Missing file placeholder
                    HStack(spacing: 6) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Image file not found on disk")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .frame(width: 360, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.white.opacity(isHovered ? 0.22 : 0.10), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                openInPreview()
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }

            // Uniform Footer Bar
            HStack(spacing: 8) {
                Button {
                    openInPreview()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                        Text("Open in Preview")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ControlCenterTokens.Colors.accentCyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(ControlCenterTokens.Colors.accentCyan.opacity(0.12))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Open full image file in macOS Preview app")

                Spacer()

                if originalWidth > 0 && originalHeight > 0 {
                    Text("\(formattedNumber(originalWidth)) × \(formattedNumber(originalHeight)) px")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .frame(width: 360)
        }
        .padding(.vertical, 4)
        .task(id: imagePath) {
            await loadThumbnailAsync()
        }
    }

    private func openInPreview() {
        let url = URL(fileURLWithPath: imagePath)
        guard FileManager.default.fileExists(atPath: imagePath) else { return }
        NSWorkspace.shared.open(url)
    }

    private func loadThumbnailAsync() async {
        // Synchronous fast check from cache
        if let cached = ImageThumbnailCache.shared.get(path: imagePath) {
            self.thumbnail = cached.image
            self.originalWidth = cached.width
            self.originalHeight = cached.height
            self.isLoading = false
            return
        }

        // Background asynchronous generation
        self.isLoading = true
        if let loaded = await ImageThumbnailCache.shared.load(path: imagePath) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.thumbnail = loaded.image
                self.originalWidth = loaded.width
                self.originalHeight = loaded.height
                self.isLoading = false
            }
        } else {
            self.isLoading = false
        }
    }

    private func formattedNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}
