import CoreGraphics
import Foundation

/// Central configuration for all cat animation parameters.
/// Tune timing, frame counts, and behavior here — not scattered across views or controllers.
/// Parameters are grouped by the behavior or clip they govern.
enum CatAnimationConfig {

    // MARK: - Render

    enum Render {
        static let frameSize     = CGSize(width: 40, height: 40)
        static let displayScale: CGFloat = 4   // renders at 160×160 pt
    }

    // MARK: - Mouse interaction

    enum Mouse {
        /// Cursor proximity required before the cat even considers reacting.
        static let noticeDistance: CGFloat = 240

        /// Tighter proximity where the cat treats the cursor like an in-your-face poke.
        static let pouncePadding: CGFloat = 40

        /// The cat should stay mostly autonomous, so only some proximity checks trigger.
        static let reactionChance: Double = 0.32

        /// Prevent repeated reactions while the cursor lingers nearby.
        static let reactionCooldown: TimeInterval = 2.8
    }

    // MARK: - Idle

    enum Idle {
        static let asset: SpriteAsset = .idle
        static let frameCount = 8

        static let frameDurations: [TimeInterval] = [
            0.13, 0.12, 0.12, 0.13,
            0.13, 0.12, 0.12, 0.13,
        ]

        /// How many full idle cycles to play before potentially transitioning to walk.
        static let cyclesMin = 3
        static let cyclesMax = 8

        /// Short pause between consecutive idle cycles.
        static let loopPauseMin: TimeInterval = 0.05
        static let loopPauseMax: TimeInterval = 0.25

        /// Probability per idle phase that a blink is inserted after an idle cycle.
        static let blinkVariationChance: Double = 0.25

        enum Blink {
            static let asset: SpriteAsset = .idleBlink
            static let frameCount = 8

            // Frame 3 = eyes fully closed — hold slightly longer
            static let frameDurations: [TimeInterval] = [
                0.10, 0.08, 0.07, 0.13,
                0.07, 0.07, 0.09, 0.10,
            ]
        }
    }

    // MARK: - Walk

    enum Walk {
        static let asset: SpriteAsset = .walk
        static let frameCount = 8

        static let frameDurations: [TimeInterval] = [
            0.10, 0.10, 0.10, 0.10,
            0.10, 0.10, 0.10, 0.10,
        ]

        /// Points per second the window moves while walking.
        static let speed: CGFloat = 80

        /// Probability that a walk episode follows an idle phase.
        static let chance: Double = 0.25

        /// How long (seconds) a walk episode lasts before returning to idle.
        static let durationMin: TimeInterval = 2
        static let durationMax: TimeInterval = 7.0

        static let toRunChance: Double    = 0.22
        static let toDashChance: Double   = 0.08
        static let toCrouchChance: Double = 0.14
        static let toFrightChance: Double = 0.05
        static let toHopChance: Double    = 0.11
    }

    // MARK: - Sneak

    enum Sneak {
        static let asset: SpriteAsset = .sneak
        static let frameCount = 8

        static let frameDurations: [TimeInterval] = [
            0.12, 0.12, 0.12, 0.12,
            0.12, 0.12, 0.12, 0.12,
        ]

        /// Points per second the window moves while sneaking.
        static let speed: CGFloat = 38

        /// Probability that a sneak episode follows an idle phase.
        static let chance: Double = 0.06

        /// How long a sneak episode lasts before resolving.
        static let durationMin: TimeInterval = 1.0
        static let durationMax: TimeInterval = 2.3

        static let toWalkChance: Double    = 0.25
        static let toSitChance: Double     = 0.25
        static let toLieDownChance: Double = 0.20
        static let toAttackChance: Double  = 0.10
        static let toHopChance: Double     = 0.08
    }

    // MARK: - Run

    enum Run {
        static let asset: SpriteAsset = .run
        static let frameCount = 4

        static let frameDurations: [TimeInterval] = [
            0.07, 0.07, 0.07, 0.07,
        ]

        /// Points per second the window moves while running.
        static let speed: CGFloat = 160

        /// Probability that a run episode follows an idle phase. Lower than walk.
        static let chance: Double = 0.08

        /// How long (seconds) a run burst lasts before settling down.
        static let durationMin: TimeInterval = 0.7
        static let durationMax: TimeInterval = 3.2

        /// How often a run burst cools back down into walking instead of stopping outright.
        static let toWalkChance: Double = 0.40

        /// How often a run burst resolves into a sit before returning to idle.
        static let toSitChance: Double = 0.20

        /// How often a run burst spikes into a one-shot dash.
        static let toDashChance: Double = 0.12
        static let toHopChance: Double  = 0.10

        /// Dedicated combo branches that turn a run into a leap-slide sequence.
        static let toSlideComboChance:       Double = 0.12
        static let toSlideAttackComboChance: Double = 0.07

        /// Duration of the calmer walk cooldown after a run resolves into walking.
        static let walkCooldownDurationMin: TimeInterval = 0.8
        static let walkCooldownDurationMax: TimeInterval = 1.6

        enum Turbo {
            /// Some run bursts should feel like a sudden zoom instead of the normal gait.
            static let chance:           Double   = 0.18
            static let speedMultiplier:  CGFloat  = 2
            static let skidChance:       Double   = 0.4
        }

        enum ComboLeap {
            static let jumpSpeed: CGFloat = 154
            static let fallSpeed: CGFloat = 112
            static let landSpeed: CGFloat = 54
        }

        enum Slide {
            static let speed:        CGFloat      = 118
            static let durationMin:  TimeInterval = 0.28
            static let durationMax:  TimeInterval = 0.52
        }

        enum SlideAttack {
            static let jumpSpeed: CGFloat = 132
            static let fallSpeed: CGFloat = 98
            static let landSpeed: CGFloat = 48
        }
    }

    // MARK: - Dash

    enum Dash {
        static let asset: SpriteAsset = .dash
        static let frameCount = 9

        static let frameDurations: [TimeInterval] = [
            0.045, 0.045, 0.04, 0.04, 0.04, 0.04, 0.045, 0.05, 0.055,
        ]

        /// Points per second the window moves while dashing.
        static let speed: CGFloat = 240

        /// Probability that a dash episode follows an idle phase.
        static let chance: Double = 0.03

        static let fromIdleToWalkChance: Double = 0.45
        static let fromIdleToRunChance:  Double = 0.25
    }

    // MARK: - Crouch

    enum Crouch {
        static let asset: SpriteAsset = .crouch
        static let frameCount = 8

        static let frameDurations: [TimeInterval] = [
            0.09, 0.09, 0.09, 0.10,
            0.10, 0.10, 0.11, 0.12,
        ]

        /// Probability that a crouch episode follows an idle phase.
        static let chance: Double = 0.07

        /// How long to hold the final crouched frame before resolving.
        static let holdMin: TimeInterval = 0.5
        static let holdMax: TimeInterval = 1.2

        static let toSneakChance:   Double = 0.24
        static let toLieDownChance: Double = 0.18
        static let toSitChance:     Double = 0.16
        static let toHopChance:     Double = 0.14
        static let toAttackChance:  Double = 0.12
    }

    // MARK: - Sit

    enum Sit {
        static let asset: SpriteAsset = .sit
        static let frameCount = 8

        static let frameDurations: [TimeInterval] = [
            0.12, 0.12, 0.12, 0.12,
            0.12, 0.12, 0.12, 0.12,
        ]

        /// Probability that a sit episode follows an idle phase.
        static let chance: Double = 0.15

        /// How many full sit cycles to play before returning to idle.
        static let cyclesMin = 2
        static let cyclesMax = 5

        static let toCrouchChance:  Double = 0.16
        static let toSneakChance:   Double = 0.05

        /// Probability that a sit episode softens further into lie-down before returning to idle.
        static let toLieDownChance: Double = 0.30
    }

    // MARK: - LieDown

    enum LieDown {
        static let asset: SpriteAsset = .lieDown
        static let frameCount = 24

        /// A slightly slower settle-in motion so the transition reads as intentional.
        static let frameDurations = Array(repeating: 0.06 as TimeInterval, count: frameCount)

        /// Probability that a lie-down episode follows an idle phase.
        static let chance: Double = 0.07

        /// Time spent resting in the lying state before returning to idle.
        static let restMin: TimeInterval = 3.5
        static let restMax: TimeInterval = 6.0

        /// Only the first 8 sliced frames are used for the lie-down behavior.
        static let activeRange = 0...7

        /// Slower resting cadence so the lie-down loop breathes instead of chattering.
        static let restFrameDuration:      TimeInterval = 0.11
        static let restStillFrameDuration: TimeInterval = 0.18
        static let restLoopPauseMin:       TimeInterval = 0.08
        static let restLoopPauseMax:       TimeInterval = 0.22

        /// Brief sit beat after lying down so the cat rises naturally before idling.
        static let exitSitCycles = 1

        static let toCrouchChance: Double = 0.18
        static let toSneakChance:  Double = 0.12
    }

    // MARK: - Sleep

    enum Sleep {
        static let asset: SpriteAsset = .sleep
        static let frameCount = 8

        static let frameDurations: [TimeInterval] = [
            0.15, 0.15, 0.15, 0.15,
            0.15, 0.15, 0.15, 0.15,
        ]

        /// Probability that a sleep episode follows a lie-down phase.
        static let chance: Double = 0.40

        /// How long (seconds) a sleep episode lasts before waking up.
        static let durationMin: TimeInterval = 10.0
        static let durationMax: TimeInterval = 25.0
    }

    // MARK: - Attack

    enum Attack {
        static let asset: SpriteAsset = .attack
        static let frameCount = 7

        /// Quick snappy one-shot burst — front-loaded then eases off.
        static let frameDurations: [TimeInterval] = [
            0.055, 0.06, 0.065, 0.065, 0.065, 0.07, 0.075,
        ]

        /// Probability per idle phase that an attack fires.
        static let chance: Double = 0.04

        static let toFrightChance: Double = 0.14   // recoil after striking
        static let toCrouchChance: Double = 0.25
        static let toSitChance:    Double = 0.15
        static let toWalkChance:   Double = 0.12
    }

    // MARK: - Fright

    enum Fright {
        static let asset: SpriteAsset = .fright
        static let frameCount = 8

        /// Startled reaction — quick initial spike, then a brief held recoil.
        static let frameDurations: [TimeInterval] = [
            0.06, 0.07, 0.09, 0.10, 0.10, 0.09, 0.08, 0.08,
        ]

        /// Probability per idle phase that a fright fires.
        static let chance: Double = 0.03

        /// How long to hold the last fright frame before resolving (reads as "frozen in shock").
        static let holdMin: TimeInterval = 0.15
        static let holdMax: TimeInterval = 0.40

        static let toRunChance:    Double = 0.14
        static let toCrouchChance: Double = 0.30
        static let toSneakChance:  Double = 0.20
    }

    // MARK: - Aerial (shared clips)

    enum Aerial {
        /// Bias vertical behaviors based on where the cat already is on screen.
        static let verticalBiasInset: CGFloat              = 180
        static let topScreenDescentBonusChance: Double     = 0.20
        static let bottomScreenAscentBonusChance: Double   = 0.20
        static let bottomScreenWallBonusChance: Double     = 0.18

        enum Jump {
            static let asset: SpriteAsset = .jump
            static let frameCount = 4

            static let frameDurations: [TimeInterval] = [
                0.06, 0.07, 0.08, 0.08,
            ]
        }

        enum Fall {
            static let asset: SpriteAsset = .fall
            static let frameCount = 3

            static let frameDurations: [TimeInterval] = [
                0.07, 0.08, 0.09,
            ]
        }

        enum Land {
            static let asset: SpriteAsset = .land
            static let frameCount = 2

            static let frameDurations: [TimeInterval] = [
                0.08, 0.11,
            ]
        }
    }

    // MARK: - Hop

    enum Hop {
        /// Probability that a hop episode follows an idle phase.
        static let chance: Double = 0.05

        /// Per-phase horizontal speed for the hop sequence.
        static let jumpSpeed: CGFloat = 118
        static let fallSpeed: CGFloat = 92
        static let landSpeed: CGFloat = 46

        /// Deterministic sprite-space arc for launch, descent, and recovery.
        static let jumpVerticalOffsets: [CGFloat] = [-8, -18, -28, -22]
        static let fallVerticalOffsets: [CGFloat] = [-16, -9, -4]
        static let landVerticalOffsets: [CGFloat] = [-2, 0]

        /// Occasionally extend the fall slightly so the arc does not feel identical every time.
        static let extendedFallChance:          Double    = 0.35
        static let extendedFallVerticalOffsets: [CGFloat] = [-16, -10, -6, -3]
        static let extendedFallFrameIndices:    [Int]     = [0, 1, 2, 2]

        /// Landing resolutions by origin.
        static let fromIdleToWalkChance:    Double = 0.22
        static let fromIdleToCrouchChance:  Double = 0.18
        static let fromWalkToWalkChance:    Double = 0.45
        static let fromWalkToRunChance:     Double = 0.14
        static let fromRunToRunChance:      Double = 0.30
        static let fromRunToWalkChance:     Double = 0.24
        static let fromCrouchToCrouchChance: Double = 0.22
        static let fromSneakToCrouchChance:  Double = 0.34
    }

    // MARK: - SkyClimb

    enum SkyClimb {
        static let chance: Double = 0.08

        /// Multi-hop screen climb tuning.
        static let hopCountMin = 2
        static let hopCountMax = 5
        static let jumpSpeed: CGFloat              = 46
        static let jumpVerticalOffsets: [CGFloat]  = [-10, -22, -36, -26]
        static let jumpVerticalMoves: [CGFloat]    = [16, 28, 34, 20]
        static let stepPauseMin: TimeInterval      = 0.04
        static let stepPauseMax: TimeInterval      = 0.12
        static let fallSpeed: CGFloat              = 72
        static let fallVerticalOffsets: [CGFloat]  = [-14, -2, 18, 40, 66, 94]
        static let fallVerticalMoves: [CGFloat]    = [-22, -38, -56, -74, -94, -118]
        static let fallFrameIndices: [Int]         = [0, 1, 2, 2, 2, 2]
        static let landSpeed: CGFloat              = 36
    }

    // MARK: - SkyDescent

    enum SkyDescent {
        static let chance: Double = 0.05

        /// Long descending screen drop tuning.
        static let jumpSpeed: CGFloat              = 84
        static let jumpVerticalOffsets: [CGFloat]  = [-6, -12, -18, -12]
        static let jumpVerticalMoves: [CGFloat]    = [4, 8, 10, 6]
        static let fallSpeed: CGFloat              = 96
        static let fallVerticalOffsets: [CGFloat]  = [-8, 8, 28, 54, 82, 112, 140, 166]
        static let fallVerticalMoves: [CGFloat]    = [-16, -28, -44, -62, -84, -106, -130, -150]
        static let fallFrameIndices: [Int]         = [0, 1, 2, 2, 2, 2, 2, 2]
        static let landSpeed: CGFloat              = 40
    }

    // MARK: - WallGrab

    enum WallGrab {
        static let asset: SpriteAsset = .wallGrab
        static let frameCount = 8

        /// Deliberate cling cadence — slow enough to read as a held grip.
        static let frameDurations: [TimeInterval] = [
            0.13, 0.13, 0.13, 0.14,
            0.14, 0.13, 0.13, 0.13,
        ]

        /// Probability per idle phase that a wall behavior triggers (only fires when at an edge).
        static let chance: Double = 0.14

        /// How many wallGrab loops to hold before deciding to climb or release.
        static let holdCyclesMin = 3
        static let holdCyclesMax = 7

        /// Probability that a grab hold transitions into a climb rather than releasing.
        static let toClimbChance: Double = 0.85
    }

    // MARK: - WallClimb

    enum WallClimb {
        static let asset: SpriteAsset = .wallClimb
        static let frameCount = 8

        /// Labored upward movement cadence — slightly slower than walk.
        static let frameDurations: [TimeInterval] = [
            0.10, 0.10, 0.11, 0.11,
            0.11, 0.10, 0.10, 0.10,
        ]

        /// Points per second the window moves upward while wall-climbing.
        static let speed: CGFloat = 64

        /// How long the cat climbs before stopping.
        static let durationMin: TimeInterval = 2.6
        static let durationMax: TimeInterval = 5.2

        /// Probability that after climbing, the cat grabs again vs dropping to idle.
        static let toGrabChance: Double = 0.08

        /// Treat "near the edge" as a valid wall zone so wall behavior appears more often.
        static let detectionInset: CGFloat = 80

        /// Dramatic wall push-off and long drop tuning.
        static let jumpOffSpeed: CGFloat              = 140
        static let jumpOffVerticalOffsets: [CGFloat]  = [-4, -14, -24, -18]
        static let jumpOffVerticalMoves: [CGFloat]    = [8, 16, 24, 14]
        static let fallSpeed: CGFloat                 = 110
        static let fallVerticalOffsets: [CGFloat]     = [-8, 4, 18, 34, 52, 70, 88, 104]
        static let fallVerticalMoves: [CGFloat]       = [-18, -30, -42, -56, -70, -84, -96, -110]
        static let fallFrameIndices: [Int]            = [0, 1, 2, 2, 2, 2, 2, 2]
        static let landSpeed: CGFloat                 = 44
    }
}
