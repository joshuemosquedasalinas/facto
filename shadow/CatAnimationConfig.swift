import CoreGraphics
import Foundation

/// Central configuration for all cat animation parameters.
/// Tune timing, frame counts, and behavior here — not scattered across views or controllers.
enum CatAnimationConfig {

    // MARK: - Render

    static let frameSize     = CGSize(width: 40, height: 40)
    static let displayScale: CGFloat = 4   // renders at 160×160 pt

    // MARK: - idle clip

    static let idleAsset      = "cat05_idle_strip8"
    static let idleFrameCount = 8

    static let idleFrameDurations: [TimeInterval] = [
        0.13, 0.12, 0.12, 0.13,
        0.13, 0.12, 0.12, 0.13,
    ]

    // MARK: - idleBlink clip

    static let idleBlinkAsset      = "cat05_idle_blink_strip8"
    static let idleBlinkFrameCount = 8

    // Frame 3 = eyes fully closed — hold slightly longer
    static let idleBlinkFrameDurations: [TimeInterval] = [
        0.10, 0.08, 0.07, 0.13,
        0.07, 0.07, 0.09, 0.10,
    ]

    // MARK: - walk clip

    static let walkAsset      = "cat05_walk_strip8"
    static let walkFrameCount = 8

    static let walkFrameDurations: [TimeInterval] = [
        0.10, 0.10, 0.10, 0.10,
        0.10, 0.10, 0.10, 0.10,
    ]

    /// Points per second the window moves while walking.
    static let walkSpeed: CGFloat = 80

    // MARK: - Idle behavior

    /// How many full idle cycles to play before potentially transitioning to walk.
    static let idleCyclesMin = 3
    static let idleCyclesMax = 8

    /// Short pause between consecutive idle cycles.
    static let idleLoopPauseMin: TimeInterval = 0.05
    static let idleLoopPauseMax: TimeInterval = 0.25

    /// Probability per idle phase that a blink is inserted after an idle cycle.
    static let blinkVariationChance: Double = 0.25

    // MARK: - Walk behavior

    /// Probability that a walk episode follows an idle phase.
    static let walkChance: Double = 0.35

    /// How long (seconds) a walk episode lasts before returning to idle.
    static let walkDurationMin: TimeInterval = 1.5
    static let walkDurationMax: TimeInterval = 4.0

    // MARK: - sit clip

    static let sitAsset      = "cat05_sit_strip8"
    static let sitFrameCount = 8

    static let sitFrameDurations: [TimeInterval] = [
        0.12, 0.12, 0.12, 0.12,
        0.12, 0.12, 0.12, 0.12,
    ]

    // MARK: - Sit behavior

    /// Probability that a sit episode follows an idle phase.
    static let sitChance: Double = 0.20

    /// How many full sit cycles to play before returning to idle.
    static let sitCyclesMin = 2
    static let sitCyclesMax = 5

    // MARK: - lieDown clip

    static let lieDownAsset      = "cat05_liedown_strip24"
    static let lieDownFrameCount = 24

    /// A slightly slower settle-in motion so the transition reads as intentional.
    static let lieDownFrameDurations = Array(repeating: 0.06, count: lieDownFrameCount)

    // MARK: - LieDown behavior

    /// Probability that a lie-down episode follows an idle phase.
    static let lieDownChance: Double = 0.10

    /// Probability that a sit episode softens further into lie-down before returning to idle.
    static let lieDownFromSitChance: Double = 0.30

    /// Time spent resting in the lying state before returning to idle.
    static let lieDownRestMin: TimeInterval = 3.5
    static let lieDownRestMax: TimeInterval = 6.0

    /// Only the first 8 sliced frames are used for the lie-down behavior.
    static let lieDownActiveRange = 0...7

    /// Slower resting cadence so the lie-down loop breathes instead of chattering.
    static let lieDownRestFrameDuration: TimeInterval = 0.11
    static let lieDownRestStillFrameDuration: TimeInterval = 0.18
    static let lieDownRestLoopPauseMin: TimeInterval = 0.08
    static let lieDownRestLoopPauseMax: TimeInterval = 0.22

    /// Brief sit beat after lying down so the cat rises naturally before idling.
    static let lieDownExitSitCycles = 1
}
