import AppKit
import SwiftUI

/// Behaviors that involve little to no window movement.
enum RestBehaviors {

    @MainActor
    static func runIdlePhase(context: CatBehaviorContext) async {
        context.updateState(.idle)
        let cycles = Int.random(in: CatAnimationConfig.Idle.cyclesMin...CatAnimationConfig.Idle.cyclesMax)

        for _ in 0..<cycles {
            guard !Task.isCancelled else { return }

            await context.player.playClip(.idle)
            guard !Task.isCancelled else { return }

            if await context.reactToNearbyMouseIfNeeded() {
                return
            }

            let pause = TimeInterval.random(
                in: CatAnimationConfig.Idle.loopPauseMin...CatAnimationConfig.Idle.loopPauseMax
            )
            try? await Task.sleep(for: .seconds(pause))

            if Double.random(in: 0..<1) < CatAnimationConfig.Idle.blinkVariationChance {
                await context.player.playClip(.idleBlink)
                guard !Task.isCancelled else { return }
                if await context.reactToNearbyMouseIfNeeded() {
                    return
                }
            }
        }
    }

    @MainActor
    static func runSitPhase(context: CatBehaviorContext, onTransition: (CatBehaviorRequest) async -> Void) async {
        context.updateState(.sit)
        let cycles = Int.random(in: CatAnimationConfig.Sit.cyclesMin...CatAnimationConfig.Sit.cyclesMax)

        for _ in 0..<cycles {
            guard !Task.isCancelled else { return }
            await context.player.playClip(.sit)
            guard !Task.isCancelled else { return }

            if await context.reactToNearbyMouseIfNeeded() {
                return
            }
        }

        let roll = Double.random(in: 0..<1)
        if roll < CatAnimationConfig.Sit.toCrouchChance {
            await onTransition(.crouch(preferredFacingRight: context.currentFacingRight, origin: .sit))
        } else if roll < (CatAnimationConfig.Sit.toCrouchChance + CatAnimationConfig.Sit.toSneakChance) {
            await onTransition(.sneak(preferredDirection: nil, origin: .sit))
        } else if roll < (CatAnimationConfig.Sit.toCrouchChance + CatAnimationConfig.Sit.toSneakChance + CatAnimationConfig.Sit.toLieDownChance) {
            await onTransition(.lieDown)
        } else {
            if Double.random(in: 0..<1) < CatAnimationConfig.Idle.blinkVariationChance {
                await context.player.playClip(.idleBlink)
            }
            context.settleToIdle()
        }
    }

    @MainActor
    static func runLieDownPhase(context: CatBehaviorContext, onTransition: (CatBehaviorRequest) async -> Void) async {
        context.updateState(.lieDown)
        await context.player.playClip(.lieDown, frames: CatAnimationConfig.LieDown.activeRange)
        guard !Task.isCancelled else { return }

        let restDuration = TimeInterval.random(
            in: CatAnimationConfig.LieDown.restMin...CatAnimationConfig.LieDown.restMax
        )
        let deadline = Date().addingTimeInterval(restDuration)

        while !Task.isCancelled, Date() < deadline {
            await playRestLoop(context: context)
            guard !Task.isCancelled else { return }

            if await context.reactToNearbyMouseIfNeeded() {
                return
            }

            let pause = TimeInterval.random(
                in: CatAnimationConfig.LieDown.restLoopPauseMin...CatAnimationConfig.LieDown.restLoopPauseMax
            )
            try? await Task.sleep(for: .seconds(pause))
        }

        guard !Task.isCancelled else { return }

        let roll = Double.random(in: 0..<1)
        if roll < CatAnimationConfig.LieDown.toCrouchChance {
            await onTransition(.crouch(preferredFacingRight: context.currentFacingRight, origin: .lieDown))
        } else if roll < (CatAnimationConfig.LieDown.toCrouchChance + CatAnimationConfig.LieDown.toSneakChance) {
            await onTransition(.sneak(preferredDirection: nil, origin: .lieDown))
        } else if roll < (CatAnimationConfig.LieDown.toCrouchChance + CatAnimationConfig.LieDown.toSneakChance + CatAnimationConfig.Sleep.chance) {
            await onTransition(.sleep)
        } else {
            context.updateState(.sit)
            for _ in 0..<CatAnimationConfig.LieDown.exitSitCycles {
                guard !Task.isCancelled else { break }
                await context.player.playClip(.sit)
            }
            context.settleToIdle()
        }
    }

    @MainActor
    static func runCrouchPhase(
        context: CatBehaviorContext,
        preferredFacingRight: Bool? = nil,
        origin: CrouchOrigin = .idle,
        onTransition: (CatBehaviorRequest) async -> Void
    ) async {
        context.updateState(.crouch)
        if let preferredFacingRight {
            context.updateFacingRight(preferredFacingRight)
        }

        await context.player.playClip(.crouch)
        guard !Task.isCancelled else { return }

        context.updateFrame(CatAnimationClip.crouch.frames.last)
        let holdDuration = TimeInterval.random(
            in: CatAnimationConfig.Crouch.holdMin...CatAnimationConfig.Crouch.holdMax
        )
        try? await Task.sleep(for: .seconds(holdDuration))
        guard !Task.isCancelled else { return }

        let roll = Double.random(in: 0..<1)

        switch origin {
        case .idle, .walk:
            if roll < CatAnimationConfig.Crouch.toAttackChance {
                await onTransition(.attack)
            } else if roll < (CatAnimationConfig.Crouch.toAttackChance + CatAnimationConfig.Crouch.toHopChance) {
                await onTransition(.hop(preferredDirection: context.currentFacingRight, origin: .crouch))
            } else if roll < (CatAnimationConfig.Crouch.toAttackChance + CatAnimationConfig.Crouch.toHopChance + CatAnimationConfig.Crouch.toSneakChance) {
                await onTransition(.sneak(preferredDirection: context.currentFacingRight, origin: .crouch))
            } else if roll < (CatAnimationConfig.Crouch.toAttackChance + CatAnimationConfig.Crouch.toHopChance + CatAnimationConfig.Crouch.toSneakChance + CatAnimationConfig.Crouch.toLieDownChance) {
                await onTransition(.lieDown)
            } else if roll < (CatAnimationConfig.Crouch.toAttackChance + CatAnimationConfig.Crouch.toHopChance + CatAnimationConfig.Crouch.toSneakChance + CatAnimationConfig.Crouch.toLieDownChance + CatAnimationConfig.Crouch.toSitChance) {
                await onTransition(.sit)
            } else {
                context.settleToIdle()
            }
        default:
            context.settleToIdle()
        }
    }

    @MainActor
    static func runSleepPhase(context: CatBehaviorContext) async {
        context.updateState(.sleep)
        let sleepDuration = TimeInterval.random(
            in: CatAnimationConfig.Sleep.durationMin...CatAnimationConfig.Sleep.durationMax
        )
        let deadline = Date().addingTimeInterval(sleepDuration)

        while !Task.isCancelled, Date() < deadline {
            await context.player.playClip(.sleep)
        }

        guard !Task.isCancelled else { return }

        context.updateFrame(CatAnimationClip.sleep.frames.last)
        try? await Task.sleep(for: .seconds(0.6))

        context.updateState(.sit)
        for _ in 0..<CatAnimationConfig.LieDown.exitSitCycles {
            guard !Task.isCancelled else { break }
            await context.player.playClip(.sit)
        }

        context.settleToIdle()
    }

    @MainActor
    static func runAttackPhase(context: CatBehaviorContext, onTransition: (CatBehaviorRequest) async -> Void) async {
        context.updateState(.attack)
        await context.player.playClip(.attack)
        guard !Task.isCancelled else { return }

        let roll = Double.random(in: 0..<1)
        if roll < CatAnimationConfig.Attack.toFrightChance {
            await onTransition(.fright)
        } else if roll < (CatAnimationConfig.Attack.toFrightChance + CatAnimationConfig.Attack.toCrouchChance) {
            await onTransition(.crouch(preferredFacingRight: context.currentFacingRight, origin: .idle))
        } else if roll < (CatAnimationConfig.Attack.toFrightChance + CatAnimationConfig.Attack.toCrouchChance + CatAnimationConfig.Attack.toSitChance) {
            await onTransition(.sit)
        } else if roll < (CatAnimationConfig.Attack.toFrightChance + CatAnimationConfig.Attack.toCrouchChance + CatAnimationConfig.Attack.toSitChance + CatAnimationConfig.Attack.toWalkChance) {
            await onTransition(.walkCooldown(goRight: context.currentFacingRight))
        } else {
            context.settleToIdleFacing(context.currentFacingRight)
        }
    }

    @MainActor
    static func runFrightPhase(context: CatBehaviorContext, onTransition: (CatBehaviorRequest) async -> Void) async {
        context.updateState(.fright)
        await context.player.playClip(.fright)
        guard !Task.isCancelled else { return }

        context.updateFrame(CatAnimationClip.fright.frames.last)
        let hold = TimeInterval.random(in: CatAnimationConfig.Fright.holdMin...CatAnimationConfig.Fright.holdMax)
        try? await Task.sleep(for: .seconds(hold))
        guard !Task.isCancelled else { return }

        let roll = Double.random(in: 0..<1)
        if roll < CatAnimationConfig.Fright.toRunChance {
            await onTransition(.run(preferredDirection: context.currentFacingRight, allowWalkCooldown: true))
        } else if roll < (CatAnimationConfig.Fright.toRunChance + CatAnimationConfig.Fright.toCrouchChance) {
            await onTransition(.crouch(preferredFacingRight: context.currentFacingRight, origin: .idle))
        } else if roll < (CatAnimationConfig.Fright.toRunChance + CatAnimationConfig.Fright.toCrouchChance + CatAnimationConfig.Fright.toSneakChance) {
            await onTransition(.sneak(preferredDirection: context.currentFacingRight, origin: .idle))
        } else {
            context.settleToIdleFacing(context.currentFacingRight)
        }
    }

    // MARK: - Helpers

    @MainActor
    private static func playRestLoop(context: CatBehaviorContext) async {
        let clip = CatAnimationClip.lieDown
        let pattern = lieDownRestPatterns.randomElement() ?? []

        for index in pattern {
            guard !Task.isCancelled else { return }
            guard clip.frames.indices.contains(index) else { continue }

            context.updateFrame(clip.frames[index])

            let duration = lieDownStillFrames.contains(index)
                ? CatAnimationConfig.LieDown.restStillFrameDuration
                : CatAnimationConfig.LieDown.restFrameDuration

            try? await Task.sleep(for: .seconds(duration))
        }
    }
}

private let lieDownStillFrames: Set<Int> = [3, 4]
private let lieDownRestPatterns: [[Int]] = [
    [0, 1, 2, 3, 4, 4, 5, 6, 5, 4, 4, 3, 2, 1],
    [1, 2, 3, 3, 4, 4, 5, 5, 4, 4, 3, 2],
    [0, 1, 2, 3, 4, 4, 4, 5, 4, 3, 3, 2, 1],
    [1, 2, 3, 4, 4, 5, 6, 6, 5, 4, 4, 3, 2],
]

/// Signal from a behavior that it wants to chain into another phase.
enum CatBehaviorRequest {
    case walk
    case run(preferredDirection: Bool?, allowWalkCooldown: Bool)
    case sneak(preferredDirection: Bool?, origin: SneakOrigin)
    case dash(preferredDirection: Bool?, resolution: DashResolution)
    case crouch(preferredFacingRight: Bool?, origin: CrouchOrigin)
    case hop(preferredDirection: Bool?, origin: HopOrigin)
    case sit
    case lieDown
    case sleep
    case attack
    case fright
    case walkCooldown(goRight: Bool)
}
