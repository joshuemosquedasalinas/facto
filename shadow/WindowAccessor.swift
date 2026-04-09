import AppKit
import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    var isHovering: Bool
    var motionProxy: WindowMotionProxy

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.isOpaque                    = false
        window.backgroundColor             = .clear
        window.titleVisibility             = .hidden
        window.titlebarAppearsTransparent  = true
        window.isMovableByWindowBackground = true
        window.hasShadow                   = false
        window.styleMask.remove(.titled)
        window.styleMask.insert(.borderless)
        window.level                       = isHovering ? .floating : .normal
        motionProxy.window                 = window

        // Lock the window to exactly the sprite display size so edge detection
        // fires when the sprite itself reaches the screen boundary.
        let side = CatAnimationConfig.frameSize.width * CatAnimationConfig.displayScale
        let size = NSSize(width: side, height: side)
        if window.frame.size != size {
            window.setContentSize(size)
        }
    }
}
