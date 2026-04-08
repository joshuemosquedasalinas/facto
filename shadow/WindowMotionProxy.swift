import AppKit
import Combine

/// Holds a weak reference to the app window and provides screen-aware movement.
/// Populated by WindowAccessor once the window is available.
/// Used by CatBehaviorController to translate the window during walk episodes.
@MainActor
final class WindowMotionProxy: ObservableObject {
    weak var window: NSWindow?

    // MARK: - Screen info

    var screenBounds: CGRect {
        window?.screen?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    private var windowWidth: CGFloat { window?.frame.width ?? 200 }
    private var windowOriginX: CGFloat { window?.frame.origin.x ?? 0 }

    // MARK: - Edge detection

    var isAtLeftEdge: Bool {
        windowOriginX <= screenBounds.minX + 2
    }

    var isAtRightEdge: Bool {
        windowOriginX + windowWidth >= screenBounds.maxX - 2
    }

    // MARK: - Movement

    /// Moves the window by `dx` points, clamped to screen bounds.
    /// - Returns: `true` if the window moved in the intended direction; `false` if blocked by an edge.
    @discardableResult
    func move(dx: CGFloat) -> Bool {
        guard let window, dx != 0 else { return false }
        let bounds   = screenBounds
        let origin   = window.frame.origin
        let minX     = bounds.minX
        let maxX     = bounds.maxX - windowWidth
        let newX     = min(max(origin.x + dx, minX), maxX)
        window.setFrameOrigin(NSPoint(x: newX, y: origin.y))
        return dx > 0 ? newX > origin.x : newX < origin.x
    }
}
