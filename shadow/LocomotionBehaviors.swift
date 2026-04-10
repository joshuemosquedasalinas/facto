import AppKit
import SwiftUI

/// Behaviors that involve horizontal window movement.
enum LocomotionBehaviors {

    @MainActor
    static func runWalkPhase(context: CatBehaviorContext, onTransition: (CatBehaviorRequest) async -> Void) async {
        guard let goRight = chooseMovementDirection(context: context, preferredDirection: nil) else { return }

        let walkDuration = TimeInterval.random(
            in: CatAnimationConfig.Walk.durationMin...CatAnimationConfig.Walk.durationMax
        )
        await context.player.playMovementEpisode(
            clip: .walk,
            state: goRight ? .walkRight : .walkLeft,
            goRight: goRight,
            speed: CatAnimationConfig.Walk.speed,
            duration: walkDuration
        )
        guard !Task.isCancelled else { return }

        let transitionRoll = Double.random(in: 0..<1)
        if transitionRoll < CatAnimationConfig.Walk.toHopChance {
            await onTransition(.hop(preferredDirection: goRight, origin: .walk))
        } else if transitionRoll < (CatAnimationConfig.Walk.toHopChance + CatAnimationConfig.Walk.toDashChance) {
            await onTransition(.dash(preferredDirection: goRight, resolution: .walk))
        } else if transitionRoll < (CatAnimationConfig.Walk.toHopChance + CatAnimationConfig.Walk.toDashChance + CatAnimationConfig.Walk.toRunChance) {
            await onTransition(.run(preferredDirection: goRight, allowWalkCooldown: true))
        } else if transitionRoll < (CatAnimationConfig.Walk.toHopChance + CatAnimationConfig.Walk.toDashChance + CatAnimationConfig.Walk.toRunChance + CatAnimationConfig.Walk.toCrouchChance) {
            await onTransition(.crouch(preferredFacingRight: goRight, origin: .walk))
        } else if transitionRoll < (CatAnimationConfig.Walk.toHopChance + CatAnimationConfig.Walk.toDashChance + CatAnimationConfig.Walk.toRunChance + CatAnimationConfig.Walk.toCrouchChance + CatAnimationConfig.Walk.toFrightChance) {
            await onTransition(.fright)
        } else {
            context.settleToIdle()
        }
    }

    @MainActor
    static func runRunPhase(
        context: CatBehaviorContext,
        preferredDirection: Bool? = nil,
        allowWalkCooldown: Bool = false,
        onTransition: (CatBehaviorRequest) async -> Void
    ) async {
        guard let goRight = chooseMovementDirection(context: context, preferredDirection: preferredDirection) else { return }

        let runDuration = TimeInterval.random(
            in: CatAnimationConfig.Run.durationMin...CatAnimationConfig.Run.durationMax
        )
        let isTurboRun = Double.random(in: 0..<1) < CatAnimationConfig.Run.Turbo.chance
        let runSpeedMultiplier: CGFloat = isTurboRun ? CatAnimationConfig.Run.Turbo.speedMultiplier : 1

        await context.player.playMovementEpisode(
            clip: .run,
            state: goRight ? .runRight : .runLeft,
            goRight: goRight,
            speed: CatAnimationConfig.Run.speed * runSpeedMultiplier,
            duration: runDuration
        )
        guard !Task.isCancelled else { return }

        if isTurboRun, Double.random(in: 0..<1) < CatAnimationConfig.Run.Turbo.skidChance {
            // Turbo skid is basically Fright but resolves to Crouch
            context.updateState(.fright)
            context.updateFacingRight(goRight)
            await context.player.playClip(.fright)
            context.updateFrame(CatAnimationClip.fright.frames.last)
            try? await Task.sleep(for: .seconds(0.18))
            await onTransition(.crouch(preferredFacingRight: goRight, origin: .walk))
            return
        }

        let canAscend = context.motionProxy.isAtTopEdge != true
        let runToSlideAttackComboChance = canAscend ? CatAnimationConfig.Run.toSlideAttackComboChance : 0
        let runToSlideComboChance = canAscend ? CatAnimationConfig.Run.toSlideComboChance : 0
        let runToHopChance = canAscend ? CatAnimationConfig.Run.toHopChance : 0

        let roll = Double.random(in: 0..<1)
        if roll < runToSlideAttackComboChance {
            await runSlideAttackComboPhase(context: context, goRight: goRight, onTransition: onTransition)
        } else if roll < (runToSlideAttackComboChance + runToSlideComboChance) {
            await runSlideComboPhase(context: context, goRight: goRight, onTransition: onTransition)
        } else if roll < (runToSlideAttackComboChance + runToSlideComboChance + runToHopChance) {
            await onTransition(.hop(preferredDirection: goRight, origin: .run))
        } else if allowWalkCooldown, roll < (runToSlideAttackComboChance + runToSlideComboChance + runToHopChance + CatAnimationConfig.Run.toWalkChance) {
            await onTransition(.walkCooldown(goRight: goRight))
        } else {
            context.settleToIdle()
        }
    }

    @MainActor
    static func runSneakPhase(
        context: CatBehaviorContext,
        preferredDirection: Bool? = nil,
        origin: SneakOrigin = .idle,
        onTransition: (CatBehaviorRequest) async -> Void
    ) async {
        guard let goRight = chooseMovementDirection(context: context, preferredDirection: preferredDirection) else { return }

        let duration = TimeInterval.random(
            in: CatAnimationConfig.Sneak.durationMin...CatAnimationConfig.Sneak.durationMax
        )
        await context.player.playMovementEpisode(
            clip: .sneak,
            state: goRight ? .sneakRight : .sneakLeft,
            goRight: goRight,
            speed: CatAnimationConfig.Sneak.speed,
            duration: duration
        )
        guard !Task.isCancelled else { return }

        let roll = Double.random(in: 0..<1)
        switch origin {
        case .idle:
            if roll < CatAnimationConfig.Sneak.toAttackChance {
                await onTransition(.attack)
            } else if roll < (CatAnimationConfig.Sneak.toAttackChance + CatAnimationConfig.Sneak.toHopChance) {
                await onTransition(.hop(preferredDirection: goRight, origin: .sneak))
            } else {
                context.settleToIdle()
            }
        default:
            context.settleToIdle()
        }
    }

    @MainActor
    static func runDashPhase(
        context: CatBehaviorContext,
        preferredDirection: Bool? = nil,
        resolution: DashResolution = .idle,
        onTransition: (CatBehaviorRequest) async -> Void
    ) async {
        guard let goRight = chooseMovementDirection(context: context, preferredDirection: preferredDirection) else { return }

        await context.player.playMovementClipOnce(
            clip: .dash,
            state: goRight ? .dashRight : .dashLeft,
            goRight: goRight,
            speed: CatAnimationConfig.Dash.speed
        )
        guard !Task.isCancelled else { return }

        switch resolution {
        case .walk:
            await runWalkCooldownPhase(context: context, goRight: goRight)
        case .run:
            await onTransition(.run(preferredDirection: goRight, allowWalkCooldown: true))
        case .idle:
            let roll = Double.random(in: 0..<1)
            if roll < CatAnimationConfig.Dash.fromIdleToWalkChance {
                await runWalkCooldownPhase(context: context, goRight: goRight)
            } else if roll < (CatAnimationConfig.Dash.fromIdleToWalkChance + CatAnimationConfig.Dash.fromIdleToRunChance) {
                await onTransition(.run(preferredDirection: goRight, allowWalkCooldown: true))
            } else {
                context.settleToIdle()
            }
        }
    }

    /// Run → ComboLeap arc → ground slide → sit.
    @MainActor
    private static func runSlideComboPhase(
        context: CatBehaviorContext,
        goRight: Bool,
        onTransition: (CatBehaviorRequest) async -> Void
    ) async {
        await context.player.playAerialClip(
            clip: .jump,
            state: goRight ? .jumpRight : .jumpLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.jump.frameCount),
            verticalOffsets: CatAnimationConfig.Hop.jumpVerticalOffsets,
            speed: CatAnimationConfig.Run.ComboLeap.jumpSpeed
        )
        guard !Task.isCancelled else { return }

        await context.player.playAerialClip(
            clip: .fall,
            state: goRight ? .fallRight : .fallLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.fall.frameCount),
            verticalOffsets: CatAnimationConfig.Hop.fallVerticalOffsets,
            speed: CatAnimationConfig.Run.ComboLeap.fallSpeed
        )
        guard !Task.isCancelled else { return }

        await context.player.playAerialClip(
            clip: .land,
            state: goRight ? .landRight : .landLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.land.frameCount),
            verticalOffsets: CatAnimationConfig.Hop.landVerticalOffsets,
            speed: CatAnimationConfig.Run.ComboLeap.landSpeed
        )
        guard !Task.isCancelled else { return }

        context.updateVerticalOffset(0)

        let slideDuration = TimeInterval.random(
            in: CatAnimationConfig.Run.Slide.durationMin...CatAnimationConfig.Run.Slide.durationMax
        )
        context.updateFacingRight(goRight)
        await context.player.playMovementEpisode(
            clip: .crouch,
            state: .crouch,
            goRight: goRight,
            speed: CatAnimationConfig.Run.Slide.speed,
            duration: slideDuration
        )
        guard !Task.isCancelled else { return }

        await onTransition(.sit)
    }

    /// Run → brief crouch slide → SlideAttack arc → attack.
    @MainActor
    private static func runSlideAttackComboPhase(
        context: CatBehaviorContext,
        goRight: Bool,
        onTransition: (CatBehaviorRequest) async -> Void
    ) async {
        context.updateFacingRight(goRight)
        await context.player.playMovementEpisode(
            clip: .crouch,
            state: .crouch,
            goRight: goRight,
            speed: CatAnimationConfig.Run.Slide.speed,
            duration: CatAnimationConfig.Run.Slide.durationMin
        )
        guard !Task.isCancelled else { return }

        await context.player.playAerialClip(
            clip: .jump,
            state: goRight ? .jumpRight : .jumpLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.jump.frameCount),
            verticalOffsets: CatAnimationConfig.Hop.jumpVerticalOffsets,
            speed: CatAnimationConfig.Run.SlideAttack.jumpSpeed
        )
        guard !Task.isCancelled else { return }

        await context.player.playAerialClip(
            clip: .fall,
            state: goRight ? .fallRight : .fallLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.fall.frameCount),
            verticalOffsets: CatAnimationConfig.Hop.fallVerticalOffsets,
            speed: CatAnimationConfig.Run.SlideAttack.fallSpeed
        )
        guard !Task.isCancelled else { return }

        await context.player.playAerialClip(
            clip: .land,
            state: goRight ? .landRight : .landLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.land.frameCount),
            verticalOffsets: CatAnimationConfig.Hop.landVerticalOffsets,
            speed: CatAnimationConfig.Run.SlideAttack.landSpeed
        )
        guard !Task.isCancelled else { return }

        context.updateVerticalOffset(0)
        await onTransition(.attack)
    }

    @MainActor
    static func runWalkCooldownPhase(context: CatBehaviorContext, goRight: Bool) async {
        let duration = TimeInterval.random(
            in: CatAnimationConfig.Run.walkCooldownDurationMin...CatAnimationConfig.Run.walkCooldownDurationMax
        )
        await context.player.playMovementEpisode(
            clip: .walk,
            state: goRight ? .walkRight : .walkLeft,
            goRight: goRight,
            speed: CatAnimationConfig.Walk.speed,
            duration: duration
        )
        context.settleToIdle()
    }

    @MainActor
    static func chooseMovementDirection(context: CatBehaviorContext, preferredDirection: Bool?) -> Bool? {
        if let preferredDirection {
            if preferredDirection, context.motionProxy.isAtRightEdge { return false }
            if !preferredDirection, context.motionProxy.isAtLeftEdge { return true }
            return preferredDirection
        }

        if context.motionProxy.isAtRightEdge { return false }
        if context.motionProxy.isAtLeftEdge { return true }

        return Bool.random()
    }
}
