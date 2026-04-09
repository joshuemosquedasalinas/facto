import AppKit
import Combine
import CoreGraphics

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

    private var windowWidth: CGFloat  { window?.frame.width  ?? 200 }
    private var windowHeight: CGFloat { window?.frame.height ?? 200 }
    private var windowOriginX: CGFloat { window?.frame.origin.x ?? 0 }
    private var windowOriginY: CGFloat { window?.frame.origin.y ?? 0 }

    var windowFrame: CGRect {
        window?.frame ?? CGRect(
            x: windowOriginX,
            y: windowOriginY,
            width: windowWidth,
            height: windowHeight
        )
    }

    var windowCenter: CGPoint {
        CGPoint(x: windowFrame.midX, y: windowFrame.midY)
    }

    var cursorLocation: CGPoint {
        NSEvent.mouseLocation
    }

    // MARK: - Edge detection

    var isAtLeftEdge: Bool {
        windowOriginX <= screenBounds.minX + 2
    }

    var isAtRightEdge: Bool {
        windowOriginX + windowWidth >= screenBounds.maxX - 2
    }

    var isAtTopEdge: Bool {
        windowOriginY + windowHeight >= screenBounds.maxY - 2
    }

    var isAtBottomEdge: Bool {
        windowOriginY <= screenBounds.minY + 2
    }

    func isNearLeftEdge(within inset: CGFloat) -> Bool {
        windowOriginX <= screenBounds.minX + inset
    }

    func isNearRightEdge(within inset: CGFloat) -> Bool {
        windowOriginX + windowWidth >= screenBounds.maxX - inset
    }

    func isNearTopEdge(within inset: CGFloat) -> Bool {
        windowOriginY + windowHeight >= screenBounds.maxY - inset
    }

    func isNearBottomEdge(within inset: CGFloat) -> Bool {
        windowOriginY <= screenBounds.minY + inset
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

    /// Moves the window by `dy` points vertically, clamped to screen bounds.
    /// - Returns: `true` if the window moved in the intended direction; `false` if blocked by an edge.
    @discardableResult
    func move(dy: CGFloat) -> Bool {
        guard let window, dy != 0 else { return false }
        let bounds   = screenBounds
        let origin   = window.frame.origin
        let minY     = bounds.minY
        let maxY     = bounds.maxY - windowHeight
        let newY     = min(max(origin.y + dy, minY), maxY)
        window.setFrameOrigin(NSPoint(x: origin.x, y: newY))
        return dy > 0 ? newY > origin.y : newY < origin.y
    }

    func cursorDistanceFromWindowCenter() -> CGFloat {
        hypot(cursorLocation.x - windowCenter.x, cursorLocation.y - windowCenter.y)
    }

    func isCursorNearWindow(maxDistance: CGFloat) -> Bool {
        cursorDistanceFromWindowCenter() <= maxDistance
    }

    func isCursorVeryCloseToWindow(padding: CGFloat) -> Bool {
        windowFrame.insetBy(dx: -padding, dy: -padding).contains(cursorLocation)
    }

    func cursorIsToRightOfWindowCenter() -> Bool {
        cursorLocation.x >= windowCenter.x
    }
}
