import AppKit
import SwiftUI

/// Behaviors that involve vertical window movement or aerial arcs.
enum AerialBehaviors {

    @MainActor
    static func runHopPhase(
        context: CatBehaviorContext,
        preferredDirection: Bool? = nil,
        origin: HopOrigin = .idle,
        onTransition: (CatBehaviorRequest) async -> Void
    ) async {
        guard context.motionProxy.isAtTopEdge != true else {
            context.settleToIdleFacing(preferredDirection ?? context.currentFacingRight)
            return
        }
        guard let goRight = LocomotionBehaviors.chooseMovementDirection(context: context, preferredDirection: preferredDirection) else { return }

        let useExtendedFall = Double.random(in: 0..<1) < CatAnimationConfig.Hop.extendedFallChance
        let fallIndices = useExtendedFall ? CatAnimationConfig.Hop.extendedFallFrameIndices : Array(0..<CatAnimationClip.fall.frameCount)
        let fallOffsets = useExtendedFall ? CatAnimationConfig.Hop.extendedFallVerticalOffsets : CatAnimationConfig.Hop.fallVerticalOffsets

        await context.player.playAerialClip(
            clip: .jump,
            state: goRight ? .jumpRight : .jumpLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.jump.frameCount),
            verticalOffsets: CatAnimationConfig.Hop.jumpVerticalOffsets,
            speed: CatAnimationConfig.Hop.jumpSpeed
        )
        guard !Task.isCancelled else { return }

        await context.player.playAerialClip(
            clip: .fall,
            state: goRight ? .fallRight : .fallLeft,
            goRight: goRight,
            frameIndices: fallIndices,
            verticalOffsets: fallOffsets,
            speed: CatAnimationConfig.Hop.fallSpeed
        )
        guard !Task.isCancelled else { return }

        await context.player.playAerialClip(
            clip: .land,
            state: goRight ? .landRight : .landLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.land.frameCount),
            verticalOffsets: CatAnimationConfig.Hop.landVerticalOffsets,
            speed: CatAnimationConfig.Hop.landSpeed
        )
        guard !Task.isCancelled else { return }

        context.updateVerticalOffset(0)
        await resolveHopLanding(context: context, origin: origin, goRight: goRight, onTransition: onTransition)
    }

    @MainActor
    static func runWallBehaviorPhase(context: CatBehaviorContext, onTransition: (CatBehaviorRequest) async -> Void) async {
        let proxy = context.motionProxy
        let goRight: Bool
        if proxy.isNearRightEdge(within: CatAnimationConfig.WallClimb.detectionInset) {
            goRight = true
        } else if proxy.isNearLeftEdge(within: CatAnimationConfig.WallClimb.detectionInset) {
            goRight = false
        } else {
            goRight = context.currentFacingRight
        }

        await runWallGrabPhase(context: context, goRight: goRight, onTransition: onTransition)
    }

    @MainActor
    private static func runWallGrabPhase(context: CatBehaviorContext, goRight: Bool, onTransition: (CatBehaviorRequest) async -> Void) async {
        context.updateState(goRight ? .wallGrabRight : .wallGrabLeft)
        context.updateFacingRight(goRight)

        let holdCycles = Int.random(in: CatAnimationConfig.WallGrab.holdCyclesMin...CatAnimationConfig.WallGrab.holdCyclesMax)
        for _ in 0..<holdCycles {
            guard !Task.isCancelled else { return }
            await context.player.playClip(.wallGrab)
        }
        guard !Task.isCancelled else { return }

        if context.motionProxy.isAtTopEdge {
            await runWallDropPhase(context: context, fromWallFacingRight: goRight)
        } else {
            let grabToClimbChance = context.motionProxy.isNearBottomEdge(within: CatAnimationConfig.Aerial.verticalBiasInset)
                ? min(1, CatAnimationConfig.WallGrab.toClimbChance + 0.25)
                : CatAnimationConfig.WallGrab.toClimbChance

            if Double.random(in: 0..<1) < grabToClimbChance {
                await runWallClimbPhase(context: context, goRight: goRight, onTransition: onTransition)
            } else {
                await runWallDropPhase(context: context, fromWallFacingRight: goRight)
            }
        }
    }

    @MainActor
    private static func runWallClimbPhase(context: CatBehaviorContext, goRight: Bool, onTransition: (CatBehaviorRequest) async -> Void) async {
        guard context.motionProxy.isAtTopEdge != true else {
            await runWallDropPhase(context: context, fromWallFacingRight: goRight)
            return
        }
        context.updateState(goRight ? .wallClimbRight : .wallClimbLeft)
        context.updateFacingRight(goRight)

        let duration = TimeInterval.random(in: CatAnimationConfig.WallClimb.durationMin...CatAnimationConfig.WallClimb.durationMax)
        let deadline = Date().addingTimeInterval(duration)

        climbLoop: while !Task.isCancelled, Date() < deadline {
            for index in 0..<CatAnimationClip.wallClimb.frameCount {
                guard !Task.isCancelled, Date() < deadline else { break climbLoop }

                context.updateFrame(CatAnimationClip.wallClimb.frames[index])
                let frameDuration = CatAnimationClip.wallClimb.frameDurations[index]
                let dy = CatAnimationConfig.WallClimb.speed * CGFloat(frameDuration)

                if !context.motionProxy.move(dy: dy) {
                    break climbLoop
                }

                try? await Task.sleep(for: .seconds(frameDuration))
            }
        }
        guard !Task.isCancelled else { return }

        let climbToGrabChance = context.motionProxy.isNearBottomEdge(within: CatAnimationConfig.Aerial.verticalBiasInset)
            ? min(1, CatAnimationConfig.WallClimb.toGrabChance + 0.18)
            : CatAnimationConfig.WallClimb.toGrabChance

        if Double.random(in: 0..<1) < climbToGrabChance {
            await runWallGrabPhase(context: context, goRight: goRight, onTransition: onTransition)
        } else {
            await runWallDropPhase(context: context, fromWallFacingRight: goRight)
        }
    }

    @MainActor
    private static func runWallDropPhase(context: CatBehaviorContext, fromWallFacingRight wallFacingRight: Bool) async {
        let jumpAwayRight = !wallFacingRight

        await context.player.playWallAerialPhase(
            clip: .jump,
            state: jumpAwayRight ? .jumpRight : .jumpLeft,
            goRight: jumpAwayRight,
            frameIndices: Array(0..<CatAnimationClip.jump.frameCount),
            spriteVerticalOffsets: CatAnimationConfig.WallClimb.jumpOffVerticalOffsets,
            windowVerticalMoves: CatAnimationConfig.WallClimb.jumpOffVerticalMoves,
            horizontalSpeed: CatAnimationConfig.WallClimb.jumpOffSpeed
        )
        guard !Task.isCancelled else { return }

        await context.player.playWallAerialPhase(
            clip: .fall,
            state: jumpAwayRight ? .fallRight : .fallLeft,
            goRight: jumpAwayRight,
            frameIndices: CatAnimationConfig.WallClimb.fallFrameIndices,
            spriteVerticalOffsets: CatAnimationConfig.WallClimb.fallVerticalOffsets,
            windowVerticalMoves: CatAnimationConfig.WallClimb.fallVerticalMoves,
            horizontalSpeed: CatAnimationConfig.WallClimb.fallSpeed
        )
        guard !Task.isCancelled else { return }

        await context.player.playAerialClip(
            clip: .land,
            state: jumpAwayRight ? .landRight : .landLeft,
            goRight: jumpAwayRight,
            frameIndices: Array(0..<CatAnimationClip.land.frameCount),
            verticalOffsets: CatAnimationConfig.Hop.landVerticalOffsets,
            speed: CatAnimationConfig.WallClimb.landSpeed
        )
        context.updateVerticalOffset(0)
        context.settleToIdleFacing(jumpAwayRight)
    }

    @MainActor
    static func runSkyClimbPhase(context: CatBehaviorContext) async {
        guard context.motionProxy.isAtTopEdge != true else {
            context.settleToIdleFacing(context.currentFacingRight)
            return
        }
        let goRight = LocomotionBehaviors.chooseMovementDirection(context: context, preferredDirection: nil) ?? context.currentFacingRight
        let hopCount = Int.random(in: CatAnimationConfig.SkyClimb.hopCountMin...CatAnimationConfig.SkyClimb.hopCountMax)

        for _ in 0..<hopCount {
            guard !Task.isCancelled else { return }

            await context.player.playWallAerialPhase(
                clip: .jump,
                state: goRight ? .jumpRight : .jumpLeft,
                goRight: goRight,
                frameIndices: Array(0..<CatAnimationClip.jump.frameCount),
                spriteVerticalOffsets: CatAnimationConfig.SkyClimb.jumpVerticalOffsets,
                windowVerticalMoves: CatAnimationConfig.SkyClimb.jumpVerticalMoves,
                horizontalSpeed: CatAnimationConfig.SkyClimb.jumpSpeed
            )
            guard !Task.isCancelled else { return }

            let pause = TimeInterval.random(in: CatAnimationConfig.SkyClimb.stepPauseMin...CatAnimationConfig.SkyClimb.stepPauseMax)
            try? await Task.sleep(for: .seconds(pause))
        }

        context.updateVerticalOffset(0)
        context.settleToIdleFacing(goRight)
    }

    @MainActor
    static func runSkyDescentPhase(context: CatBehaviorContext) async {
        guard context.motionProxy.isAtBottomEdge != true else {
            context.settleToIdleFacing(context.currentFacingRight)
            return
        }
        let goRight = LocomotionBehaviors.chooseMovementDirection(context: context, preferredDirection: nil) ?? context.currentFacingRight

        await context.player.playWallAerialPhase(
            clip: .jump,
            state: goRight ? .jumpRight : .jumpLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.jump.frameCount),
            spriteVerticalOffsets: CatAnimationConfig.SkyDescent.jumpVerticalOffsets,
            windowVerticalMoves: CatAnimationConfig.SkyDescent.jumpVerticalMoves,
            horizontalSpeed: CatAnimationConfig.SkyDescent.jumpSpeed
        )
        guard !Task.isCancelled else { return }

        await context.player.playWallAerialPhase(
            clip: .fall,
            state: goRight ? .fallRight : .fallLeft,
            goRight: goRight,
            frameIndices: CatAnimationConfig.SkyDescent.fallFrameIndices,
            spriteVerticalOffsets: CatAnimationConfig.SkyDescent.fallVerticalOffsets,
            windowVerticalMoves: CatAnimationConfig.SkyDescent.fallVerticalMoves,
            horizontalSpeed: CatAnimationConfig.SkyDescent.fallSpeed
        )
        guard !Task.isCancelled else { return }

        await context.player.playAerialClip(
            clip: .land,
            state: goRight ? .landRight : .landLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.land.frameCount),
            verticalOffsets: CatAnimationConfig.Hop.landVerticalOffsets,
            speed: CatAnimationConfig.SkyDescent.landSpeed
        )
        context.updateVerticalOffset(0)
        context.settleToIdleFacing(goRight)
    }

    @MainActor
    private static func resolveHopLanding(
        context: CatBehaviorContext,
        origin: HopOrigin,
        goRight: Bool,
        onTransition: (CatBehaviorRequest) async -> Void
    ) async {
        let roll = Double.random(in: 0..<1)
        switch origin {
        case .idle:
            if roll < CatAnimationConfig.Hop.fromIdleToWalkChance {
                await onTransition(.walkCooldown(goRight: goRight))
            } else if roll < (CatAnimationConfig.Hop.fromIdleToWalkChance + CatAnimationConfig.Hop.fromIdleToCrouchChance) {
                await onTransition(.crouch(preferredFacingRight: goRight, origin: .idle))
            } else {
                context.settleToIdleFacing(goRight)
            }
        case .walk:
            if roll < CatAnimationConfig.Hop.fromWalkToWalkChance {
                await onTransition(.walkCooldown(goRight: goRight))
            } else {
                context.settleToIdleFacing(goRight)
            }
        default:
            context.settleToIdleFacing(goRight)
        }
    }
}
