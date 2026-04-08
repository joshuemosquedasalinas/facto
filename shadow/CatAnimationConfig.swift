import CoreGraphics
import Foundation

/// Central configuration for all cat animation parameters.
/// Tune timing, frame counts, and idle behavior here — not scattered across views or controllers.
enum CatAnimationConfig {

    // MARK: - idle clip

    static let idleAsset      = "cat05_idle_strip8"
    static let idleFrameCount = 8

    /// All frames similar duration — smooth, looping body animation.
    static let idleFrameDurations: [TimeInterval] = [
        0.13,   // 0
        0.12,   // 1
        0.12,   // 2
        0.13,   // 3
        0.13,   // 4
        0.12,   // 5
        0.12,   // 6
        0.13,   // 7
    ]

    /// Short pause between consecutive idle cycles (keeps the loop feeling seamless).
    static let idleLoopPauseMin: TimeInterval = 0.05
    static let idleLoopPauseMax: TimeInterval = 0.25

    // MARK: - idleBlink clip

    static let idleBlinkAsset      = "cat05_idle_blink_strip8"
    static let idleBlinkFrameCount = 8

    // Frame 0 — neutral/open eyes  (rest pose)
    // Frame 1 — eyes beginning to close
    // Frame 2 — eyes half-closed
    // Frame 3 — eyes fully closed  ← hold slightly longer
    // Frame 4 — eyes reopening
    // Frame 5 — eyes nearly open
    // Frame 6 — eyes open, settle
    // Frame 7 — neutral again
    static let idleBlinkFrameDurations: [TimeInterval] = [
        0.10,   // 0
        0.08,   // 1
        0.07,   // 2
        0.13,   // 3: fully closed — hold
        0.07,   // 4
        0.07,   // 5
        0.09,   // 6
        0.10,   // 7
    ]

    // MARK: - Render

    static let frameSize     = CGSize(width: 40, height: 40)
    static let displayScale: CGFloat = 4   // renders at 160×160 pt

    // MARK: - Variation

    /// Probability (0–1) that the controller inserts an idleBlink after each idle cycle.
    /// 0.25 = roughly one blink every 4 idle loops (~4 seconds).
    static let blinkVariationChance: Double = 0.25
}
