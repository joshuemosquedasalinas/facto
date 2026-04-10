import AppKit
import SwiftUI

/// Shared capabilities required by any behavior to influence the cat and its window.
@MainActor
protocol CatBehaviorContext: AnyObject {
    
    /// The window proxy used for screen-aware movement.
    var motionProxy: WindowMotionProxy { get }
    
    /// The animation player used for frame-by-frame playback.
    var player: AnimationPlayer { get }

    /// Updates the visual frame shown to the user.
    func updateFrame(_ image: NSImage?)

    /// Flips the sprite horizontally.
    func updateFacingRight(_ facingRight: Bool)

    /// Offsets the sprite vertically within its window (for jumps).
    func updateVerticalOffset(_ offset: CGFloat)

    /// Updates the semantic state of the cat.
    func updateState(_ state: CatState)

    /// Returns the current facing direction.
    var currentFacingRight: Bool { get }

    /// The timestamp of the last mouse-triggered reaction.
    var lastMouseReactionAt: Date { get set }
    
    /// Returns the current semantic state.
    var currentState: CatState { get }

    /// Sets everything back to a standard standing idle.
    func settleToIdle()

    /// Sets everything back to idle but maintains a specific horizontal flip.
    func settleToIdleFacing(_ goRight: Bool)

    /// Triggers a reaction if the cursor is nearby.
    func reactToNearbyMouseIfNeeded() async -> Bool
}
