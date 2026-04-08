import AppKit
import Combine
import SwiftUI

struct AnimatedCatView: View {
    let resourceName: String
    let frameCount: Int
    let frameSize: CGSize
    let scale: CGFloat

    @State private var currentFrame = 0
    private let frames: [NSImage]
    private let timer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()

    init(resourceName: String, frameCount: Int, frameSize: CGSize, scale: CGFloat) {
        self.resourceName = resourceName
        self.frameCount = frameCount
        self.frameSize = frameSize
        self.scale = scale
        self.frames = SpriteStripLoader.frames(resourceName: resourceName, frameCount: frameCount)
    }

    var body: some View {
        Group {
            if let frame = frames[safe: currentFrame] {
                Image(nsImage: frame)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: frameSize.width * scale, height: frameSize.height * scale)
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.1))
                    .frame(width: frameSize.width * scale, height: frameSize.height * scale)
            }
        }
        .onReceive(timer) { _ in
            guard !frames.isEmpty else { return }
            currentFrame = (currentFrame + 1) % frames.count
        }
    }
}

private enum SpriteStripLoader {
    static func frames(resourceName: String, frameCount: Int) -> [NSImage] {
        guard
            let url = Bundle.main.url(forResource: resourceName, withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else {
            return []
        }

        var proposedRect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil), frameCount > 0 else {
            return []
        }

        let frameWidth = cgImage.width / frameCount
        let frameHeight = cgImage.height

        return (0..<frameCount).compactMap { index in
            let rect = CGRect(x: index * frameWidth, y: 0, width: frameWidth, height: frameHeight)
            guard let cropped = cgImage.cropping(to: rect) else { return nil }

            let frame = NSImage(cgImage: cropped, size: NSSize(width: frameWidth, height: frameHeight))
            return frame
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
