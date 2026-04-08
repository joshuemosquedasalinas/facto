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

    // MARK: - sneak clip

    static let sneakAsset      = "cat05_sneak_strip8"
    static let sneakFrameCount = 8

    static let sneakFrameDurations: [TimeInterval] = [
        0.12, 0.12, 0.12, 0.12,
        0.12, 0.12, 0.12, 0.12,
    ]

    /// Points per second the window moves while sneaking.
    static let sneakSpeed: CGFloat = 38

    // MARK: - Sneak behavior

    /// Probability that a sneak episode follows an idle phase. Lower than walk.
    static let sneakChance: Double = 0.08

    /// How long a sneak episode lasts before resolving.
    static let sneakDurationMin: TimeInterval = 1.0
    static let sneakDurationMax: TimeInterval = 2.3

    /// Resolution mix after a sneak episode.
    static let sneakToWalkChance: Double = 0.22
    static let sneakToSitChance: Double = 0.20
    static let sneakToLieDownChance: Double = 0.14

    /// Probability that sit resolves into a brief sneak episode.
    static let sitToSneakChance: Double = 0.10

    /// Probability that lie-down resolves into a low crawl instead of sleep or sit.
    static let lieDownToSneakChance: Double = 0.12

    /// Probability that a completed walk burst escalates into a short run burst.
    static let walkToRunChance: Double = 0.22
    static let walkToDashChance: Double = 0.08

    /// Duration of the calmer walk cooldown after a run resolves into walking.
    static let walkCooldownDurationMin: TimeInterval = 0.8
    static let walkCooldownDurationMax: TimeInterval = 1.6

    // MARK: - run clip

    static let runAsset      = "cat05_run_strip4"
    static let runFrameCount = 4

    static let runFrameDurations: [TimeInterval] = [
        0.07, 0.07, 0.07, 0.07,
    ]

    /// Points per second the window moves while running.
    static let runSpeed: CGFloat = 160

    // MARK: - Run behavior

    /// Probability that a run episode follows an idle phase. Lower than walk.
    static let runChance: Double = 0.10

    /// How long (seconds) a run burst lasts before settling down.
    static let runDurationMin: TimeInterval = 0.7
    static let runDurationMax: TimeInterval = 1.6

    /// How often a run burst cools back down into walking instead of stopping outright.
    static let runToWalkChance: Double = 0.40

    /// How often a run burst resolves into a sit before returning to idle.
    static let runToSitChance: Double = 0.20

    /// How often a run burst spikes into a one-shot dash.
    static let runToDashChance: Double = 0.12

    // MARK: - dash clip

    static let dashAsset      = "cat05_dash_strip9"
    static let dashFrameCount = 9

    static let dashFrameDurations: [TimeInterval] = [
        0.045, 0.045, 0.04, 0.04, 0.04, 0.04, 0.045, 0.05, 0.055,
    ]

    /// Points per second the window moves while dashing.
    static let dashSpeed: CGFloat = 240

    // MARK: - Dash behavior

    /// Probability that a dash episode follows an idle phase. Lower than run.
    static let dashChance: Double = 0.03

    /// How a dash resolves when triggered directly from idle.
    static let dashFromIdleToWalkChance: Double = 0.20
    static let dashFromIdleToRunChance: Double = 0.10

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

    // MARK: - sleep clip

    static let sleepAsset      = "cat05_sleep_strip8"
    static let sleepFrameCount = 8

    static let sleepFrameDurations: [TimeInterval] = [
        0.15, 0.15, 0.15, 0.15,
        0.15, 0.15, 0.15, 0.15,
    ]

    // MARK: - Sleep behavior

    /// Probability that a sleep episode follows a lie-down phase.
    static let sleepChance: Double = 0.40

    /// How long (seconds) a sleep episode lasts before waking up.
    static let sleepDurationMin: TimeInterval = 10.0
    static let sleepDurationMax: TimeInterval = 25.0
}
