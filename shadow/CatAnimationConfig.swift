import CoreGraphics
import Foundation

/// Central configuration for all cat animation parameters.
/// Tune timing, frame counts, and idle behavior here — not scattered across views or controllers.
enum CatAnimationConfig {

    // MARK: - Asset

    static let idleBlinkAsset      = "cat05_idle_blink_strip8"
    static let idleBlinkFrameCount = 8

    // MARK: - Render

    /// Source frame dimensions (pixels in the strip).
    static let frameSize = CGSize(width: 40, height: 40)

    /// Integer scale applied for pixel-art crispness — renders at 160×160 pt.
    static let displayScale: CGFloat = 4

    // MARK: - idleBlink per-frame durations (seconds)
    //
    // Frame 0 — neutral, eyes open  (rest pose shown during idle pause)
    // Frame 1 — eyes beginning to close
    // Frame 2 — eyes half-closed
    // Frame 3 — eyes fully closed       ← hold slightly longer
    // Frame 4 — eyes reopening
    // Frame 5 — eyes nearly open
    // Frame 6 — eyes open, slight settle
    // Frame 7 — neutral again
    //
    // These durations apply only while actively playing through the clip.
    // The rest pause between cycles is separate (idlePauseMin/Max below).
    static let idleBlinkFrameDurations: [TimeInterval] = [
        0.10,   // 0: rest/open
        0.08,   // 1: closing start
        0.07,   // 2: closing mid
        0.13,   // 3: fully closed — hold
        0.07,   // 4: opening
        0.07,   // 5: opening mid
        0.09,   // 6: nearly open
        0.10,   // 7: open/settle
    ]

    // MARK: - Idle pause between blink cycles (seconds)

    /// Cat rests on the neutral frame for a random duration in this range before blinking again.
    static let idlePauseMin: TimeInterval = 2.5
    static let idlePauseMax: TimeInterval = 6.0
}
