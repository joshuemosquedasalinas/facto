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

    // MARK: - Mouse interaction

    /// Cursor proximity required before the cat even considers reacting.
    static let mouseNoticeDistance: CGFloat = 240

    /// Tighter proximity where the cat treats the cursor like an in-your-face poke.
    static let mousePouncePadding: CGFloat = 40

    /// The cat should stay mostly autonomous, so only some proximity checks trigger.
    static let mouseReactionChance: Double = 0.32

    /// Prevent repeated reactions while the cursor lingers nearby.
    static let mouseReactionCooldown: TimeInterval = 2.8

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

    /// How long a sneak episode lasts before resolving.
    static let sneakDurationMin: TimeInterval = 1.0
    static let sneakDurationMax: TimeInterval = 2.3

    /// Probability that a sneak episode follows an idle phase.
    static let sneakChance: Double = 0.08

    /// Probability that sit resolves into a brief sneak episode.
    static let sitToSneakChance: Double = 0.05

    /// Probability that lie-down resolves into a low crawl instead of sleep or sit.
    static let lieDownToSneakChance: Double = 0.12
    static let crouchToSneakChance: Double = 0.24
    static let sneakToWalkChance: Double = 0.25
    static let sneakToSitChance: Double = 0.25
    static let sneakToLieDownChance: Double = 0.20

    /// Probability that a completed walk burst escalates into a short run burst.
    static let walkToRunChance: Double = 0.22
    static let walkToDashChance: Double = 0.08

    /// Duration of the calmer walk cooldown after a run resolves into walking.
    static let walkCooldownDurationMin: TimeInterval = 0.8
    static let walkCooldownDurationMax: TimeInterval = 1.6

    // MARK: - aerial clips

    static let jumpAsset      = "cat05_jump_strip4"
    static let jumpFrameCount = 4

    static let jumpFrameDurations: [TimeInterval] = [
        0.06, 0.07, 0.08, 0.08,
    ]

    static let fallAsset      = "cat05_fall_strip3"
    static let fallFrameCount = 3

    static let fallFrameDurations: [TimeInterval] = [
        0.07, 0.08, 0.09,
    ]

    static let landAsset      = "cat05_land_strip2"
    static let landFrameCount = 2

    static let landFrameDurations: [TimeInterval] = [
        0.08, 0.11,
    ]

    // MARK: - Hop behavior

    /// Probability that a hop episode follows an idle phase.
    static let hopChance: Double = 0.05
    static let skyClimbChance: Double = 0.08
    static let skyDescentChance: Double = 0.05

    /// Bias vertical behaviors based on where the cat already is on screen.
    static let verticalBiasInset: CGFloat = 180
    static let topScreenDescentBonusChance: Double = 0.20
    static let bottomScreenAscentBonusChance: Double = 0.20
    static let bottomScreenWallBonusChance: Double = 0.18

    /// Probabilities that grounded locomotion and low postures spike into a hop.
    static let walkToHopChance: Double = 0.11
    static let runToHopChance: Double = 0.10
    static let crouchToHopChance: Double = 0.14
    static let sneakToHopChance: Double = 0.08

    /// Per-phase horizontal speed for the hop sequence.
    static let hopJumpSpeed: CGFloat = 118
    static let hopFallSpeed: CGFloat = 92
    static let hopLandSpeed: CGFloat = 46

    /// Deterministic sprite-space arc for launch, descent, and recovery.
    static let jumpVerticalOffsets: [CGFloat] = [-8, -18, -28, -22]
    static let fallVerticalOffsets: [CGFloat] = [-16, -9, -4]
    static let landVerticalOffsets: [CGFloat] = [-2, 0]

    /// Occasionally extend the fall slightly so the arc does not feel identical every time.
    static let extendedFallChance: Double = 0.35
    static let extendedFallVerticalOffsets: [CGFloat] = [-16, -10, -6, -3]
    static let extendedFallFrameIndices: [Int] = [0, 1, 2, 2]

    /// Landing resolutions by origin.
    static let hopFromIdleToWalkChance: Double = 0.22
    static let hopFromIdleToCrouchChance: Double = 0.18
    static let hopFromWalkToWalkChance: Double = 0.45
    static let hopFromWalkToRunChance: Double = 0.14
    static let hopFromRunToRunChance: Double = 0.30
    static let hopFromRunToWalkChance: Double = 0.24
    static let hopFromCrouchToCrouchChance: Double = 0.22
    static let hopFromSneakToCrouchChance: Double = 0.34

    /// Multi-hop screen climb tuning.
    static let skyClimbHopCountMin = 2
    static let skyClimbHopCountMax = 5
    static let skyClimbJumpSpeed: CGFloat = 46
    static let skyClimbJumpVerticalOffsets: [CGFloat] = [-10, -22, -36, -26]
    static let skyClimbJumpVerticalMoves: [CGFloat] = [16, 28, 34, 20]
    static let skyClimbStepPauseMin: TimeInterval = 0.04
    static let skyClimbStepPauseMax: TimeInterval = 0.12
    static let skyClimbFallSpeed: CGFloat = 72
    static let skyClimbFallVerticalOffsets: [CGFloat] = [-14, -2, 18, 40, 66, 94]
    static let skyClimbFallVerticalMoves: [CGFloat] = [-22, -38, -56, -74, -94, -118]
    static let skyClimbFallFrameIndices: [Int] = [0, 1, 2, 2, 2, 2]
    static let skyClimbLandSpeed: CGFloat = 36

    /// Long descending screen drop tuning.
    static let skyDescentJumpSpeed: CGFloat = 84
    static let skyDescentJumpVerticalOffsets: [CGFloat] = [-6, -12, -18, -12]
    static let skyDescentJumpVerticalMoves: [CGFloat] = [4, 8, 10, 6]
    static let skyDescentFallSpeed: CGFloat = 96
    static let skyDescentFallVerticalOffsets: [CGFloat] = [-8, 8, 28, 54, 82, 112, 140, 166]
    static let skyDescentFallVerticalMoves: [CGFloat] = [-16, -28, -44, -62, -84, -106, -130, -150]
    static let skyDescentFallFrameIndices: [Int] = [0, 1, 2, 2, 2, 2, 2, 2]
    static let skyDescentLandSpeed: CGFloat = 40

    // MARK: - run clip

    static let runAsset      = "cat05_run_strip4"
    static let runFrameCount = 4

    static let runFrameDurations: [TimeInterval] = [
        0.07, 0.07, 0.07, 0.07,
    ]

    /// Points per second the window moves while running.
    static let runSpeed: CGFloat = 160

    /// Some run bursts should feel like a sudden zoom instead of the normal gait.
    static let turboRunChance: Double = 0.18
    static let turboRunSpeedMultiplier: CGFloat = 2
    static let turboRunSkidChance: Double = 0.4

    // MARK: - Run behavior

    /// Probability that a run episode follows an idle phase. Lower than walk.
    static let runChance: Double = 0.10

    /// How long (seconds) a run burst lasts before settling down.
    static let runDurationMin: TimeInterval = 0.7
    static let runDurationMax: TimeInterval = 3.2

    /// How often a run burst cools back down into walking instead of stopping outright.
    static let runToWalkChance: Double = 0.40

    /// How often a run burst resolves into a sit before returning to idle.
    static let runToSitChance: Double = 0.20

    /// How often a run burst spikes into a one-shot dash.
    static let runToDashChance: Double = 0.12

    /// Dedicated combo branches that turn a run into a leap-slide sequence.
    static let runToSlideComboChance: Double = 0.12
    static let runToSlideAttackComboChance: Double = 0.07

    /// Combo leap tuning.
    static let comboLeapJumpSpeed: CGFloat = 154
    static let comboLeapFallSpeed: CGFloat = 112
    static let comboLeapLandSpeed: CGFloat = 54

    /// Sliding crouch tuning.
    static let slideSpeed: CGFloat = 118
    static let slideDurationMin: TimeInterval = 0.28
    static let slideDurationMax: TimeInterval = 0.52

    /// Follow-through leap after the slide before the pounce attack.
    static let slideAttackJumpSpeed: CGFloat = 132
    static let slideAttackFallSpeed: CGFloat = 98
    static let slideAttackLandSpeed: CGFloat = 48

    // MARK: - dash clip

    static let dashAsset      = "cat05_dash_strip9"
    static let dashFrameCount = 9

    static let dashFrameDurations: [TimeInterval] = [
        0.045, 0.045, 0.04, 0.04, 0.04, 0.04, 0.045, 0.05, 0.055,
    ]

    /// Points per second the window moves while dashing.
    static let dashSpeed: CGFloat = 240

    // MARK: - Dash behavior

    /// Probability that a dash episode follows an idle phase.
    static let dashChance: Double = 0.03
    static let dashFromIdleToWalkChance: Double = 0.45
    static let dashFromIdleToRunChance: Double = 0.25

    // MARK: - crouch clip

    static let crouchAsset      = "cat05_crouch_strip8"
    static let crouchFrameCount = 8

    static let crouchFrameDurations: [TimeInterval] = [
        0.09, 0.09, 0.09, 0.10,
        0.10, 0.10, 0.11, 0.12,
    ]

    // MARK: - Crouch behavior

    /// Probability that a crouch episode follows an idle phase.
    static let crouchChance: Double = 0.09

    /// Probability that walk decompresses into crouch before settling.
    static let walkToCrouchChance: Double = 0.14

    /// Probability that sit compresses further into crouch.
    static let sitToCrouchChance: Double = 0.16

    /// Probability that lie-down resolves through crouch instead of sneak/sleep/sit.
    static let lieDownToCrouchChance: Double = 0.18

    /// How long to hold the final crouched frame before resolving.
    static let crouchHoldMin: TimeInterval = 0.5
    static let crouchHoldMax: TimeInterval = 1.2

    /// Resolution mix after a crouch episode.
    static let crouchToLieDownChance: Double = 0.18
    static let crouchToSitChance: Double = 0.16

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

    // MARK: - attack clip

    static let attackAsset      = "cat05_attack_strip7"
    static let attackFrameCount = 7

    /// Quick snappy one-shot burst — front-loaded then eases off.
    static let attackFrameDurations: [TimeInterval] = [
        0.055, 0.06, 0.065, 0.065, 0.065, 0.07, 0.075,
    ]

    // MARK: - Attack behavior

    /// Probability per idle phase that an attack fires.
    static let attackChance: Double = 0.04

    /// Probability that a crouch hold converts to an attack lunge.
    static let crouchToAttackChance: Double = 0.12

    /// Probability that a sneak episode ends in an attack.
    static let sneakToAttackChance: Double = 0.10

    /// Post-attack resolutions.
    static let attackToFrightChance: Double = 0.14   // recoil after striking
    static let attackToCrouchChance: Double = 0.25
    static let attackToSitChance: Double    = 0.15
    static let attackToWalkChance: Double   = 0.12

    // MARK: - fright clip

    static let frightAsset      = "cat05_fright_strip8"
    static let frightFrameCount = 8

    /// Startled reaction — quick initial spike, then a brief held recoil.
    static let frightFrameDurations: [TimeInterval] = [
        0.06, 0.07, 0.09, 0.10, 0.10, 0.09, 0.08, 0.08,
    ]

    // MARK: - Fright behavior

    /// Probability per idle phase that a fright fires.
    static let frightChance: Double = 0.03

    /// How long to hold the last fright frame before resolving (reads as "frozen in shock").
    static let frightHoldMin: TimeInterval = 0.15
    static let frightHoldMax: TimeInterval = 0.40

    /// Probability that a walk episode ends in a fright (unexpected stop).
    static let walkToFrightChance: Double = 0.05

    /// Post-fright resolutions.
    static let frightToRunChance:    Double = 0.14
    static let frightToCrouchChance: Double = 0.30
    static let frightToSneakChance:  Double = 0.20

    // MARK: - wallGrab clip

    static let wallGrabAsset      = "cat05_wallgrab_strip8"
    static let wallGrabFrameCount = 8

    /// Deliberate cling cadence — slow enough to read as a held grip.
    static let wallGrabFrameDurations: [TimeInterval] = [
        0.13, 0.13, 0.13, 0.14,
        0.14, 0.13, 0.13, 0.13,
    ]

    // MARK: - wallClimb clip

    static let wallClimbAsset      = "cat05_wallclimb_strip8"
    static let wallClimbFrameCount = 8

    /// Labored upward movement cadence — slightly slower than walk.
    static let wallClimbFrameDurations: [TimeInterval] = [
        0.10, 0.10, 0.11, 0.11,
        0.11, 0.10, 0.10, 0.10,
    ]

    /// Points per second the window moves upward while wall-climbing.
    static let wallClimbSpeed: CGFloat = 64

    // MARK: - Wall behavior

    /// Probability per idle phase that a wall behavior triggers (only fires when at an edge).
    static let wallGrabChance: Double = 0.14

    /// How many wallGrab loops to hold before deciding to climb or release.
    static let wallGrabHoldCyclesMin = 3
    static let wallGrabHoldCyclesMax = 7

    /// How long the cat climbs before stopping.
    static let wallClimbDurationMin: TimeInterval = 2.6
    static let wallClimbDurationMax: TimeInterval = 5.2

    /// Probability that a grab hold transitions into a climb rather than releasing.
    static let wallGrabToClimbChance: Double = 0.85

    /// Probability that after climbing, the cat grabs again vs dropping to idle.
    static let wallClimbToGrabChance: Double = 0.08

    /// Treat "near the edge" as a valid wall zone so wall behavior appears more often.
    static let wallDetectionInset: CGFloat = 80

    /// Dramatic wall push-off and long drop tuning.
    static let wallJumpOffSpeed: CGFloat = 140
    static let wallJumpOffVerticalOffsets: [CGFloat] = [-4, -14, -24, -18]
    static let wallJumpOffVerticalMoves: [CGFloat] = [8, 16, 24, 14]
    static let wallFallSpeed: CGFloat = 110
    static let wallFallVerticalOffsets: [CGFloat] = [-8, 4, 18, 34, 52, 70, 88, 104]
    static let wallFallVerticalMoves: [CGFloat] = [-18, -30, -42, -56, -70, -84, -96, -110]
    static let wallFallFrameIndices: [Int] = [0, 1, 2, 2, 2, 2, 2, 2]
    static let wallLandSpeed: CGFloat = 44
}
