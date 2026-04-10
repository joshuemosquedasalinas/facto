import Foundation

/// Routes top-level behavior selection and chained CatBehaviorRequests to the appropriate module.
/// Extracted from CatBehaviorController so the controller stays focused on observable state and lifecycle.
@MainActor
enum BehaviorDispatcher {

    /// Selects and runs one top-level behavior after an idle phase completes.
    ///
    /// Each behavior fires with its configured base probability. Aerial and wall behaviors
    /// are gated on position (can't climb if already at the top edge) and gain bonus
    /// probability when the cat is near the relevant screen boundary.
    static func selectNextBehavior(context: CatBehaviorContext) async {
        let proxy = context.motionProxy
        let dispatch: (CatBehaviorRequest) async -> Void = { await handle($0, context: context) }

        // Screen-position gates and biases
        let canAscend    = proxy.isAtTopEdge != true
        let canDescend   = proxy.isAtBottomEdge != true
        let nearBottom   = proxy.isNearBottomEdge(within: CatAnimationConfig.Aerial.verticalBiasInset)
        let nearTop      = proxy.isNearTopEdge(within: CatAnimationConfig.Aerial.verticalBiasInset)
        let hopChance = canAscend ? CatAnimationConfig.Hop.chance : 0

        let skyClimbChance = canAscend
            ? CatAnimationConfig.SkyClimb.chance + (nearBottom ? CatAnimationConfig.Aerial.bottomScreenAscentBonusChance : 0)
            : 0

        let skyDescentChance = canDescend
            ? CatAnimationConfig.SkyDescent.chance + (nearTop ? CatAnimationConfig.Aerial.topScreenDescentBonusChance : 0)
            : 0

        let wallGrabChance = CatAnimationConfig.WallGrab.chance
            + (nearBottom ? CatAnimationConfig.Aerial.bottomScreenWallBonusChance : 0)

        let roll = Double.random(in: 0..<1)
        var t = 0.0

        t += CatAnimationConfig.Walk.chance
        if roll < t { await LocomotionBehaviors.runWalkPhase(context: context, onTransition: dispatch); return }

        t += CatAnimationConfig.Run.chance
        if roll < t { await LocomotionBehaviors.runRunPhase(context: context, onTransition: dispatch); return }

        t += CatAnimationConfig.Sit.chance
        if roll < t { await RestBehaviors.runSitPhase(context: context, onTransition: dispatch); return }

        t += CatAnimationConfig.LieDown.chance
        if roll < t { await RestBehaviors.runLieDownPhase(context: context, onTransition: dispatch); return }

        t += CatAnimationConfig.Sneak.chance
        if roll < t { await LocomotionBehaviors.runSneakPhase(context: context, onTransition: dispatch); return }

        t += CatAnimationConfig.Crouch.chance
        if roll < t { await RestBehaviors.runCrouchPhase(context: context, onTransition: dispatch); return }

        t += CatAnimationConfig.Attack.chance
        if roll < t { await RestBehaviors.runAttackPhase(context: context, onTransition: dispatch); return }

        t += CatAnimationConfig.Fright.chance
        if roll < t { await RestBehaviors.runFrightPhase(context: context, onTransition: dispatch); return }

        t += CatAnimationConfig.Dash.chance
        if roll < t { await LocomotionBehaviors.runDashPhase(context: context, resolution: .idle, onTransition: dispatch); return }

        t += hopChance
        if roll < t { await AerialBehaviors.runHopPhase(context: context, onTransition: dispatch); return }

        t += skyClimbChance
        if roll < t { await AerialBehaviors.runSkyClimbPhase(context: context); return }

        t += skyDescentChance
        if roll < t { await AerialBehaviors.runSkyDescentPhase(context: context); return }

        t += wallGrabChance
        if roll < t { await AerialBehaviors.runWallBehaviorPhase(context: context, onTransition: dispatch); return }

        // Remainder falls back to idle — the loop picks up naturally on the next iteration.
    }

    /// Dispatches a chained behavior request to the appropriate module.
    static func handle(_ request: CatBehaviorRequest, context: CatBehaviorContext) async {
        let dispatch: (CatBehaviorRequest) async -> Void = { await handle($0, context: context) }
        switch request {
        case .walk:
            await LocomotionBehaviors.runWalkPhase(context: context, onTransition: dispatch)
        case .run(let dir, let cooldown):
            await LocomotionBehaviors.runRunPhase(context: context, preferredDirection: dir, allowWalkCooldown: cooldown, onTransition: dispatch)
        case .sneak(let dir, let origin):
            await LocomotionBehaviors.runSneakPhase(context: context, preferredDirection: dir, origin: origin, onTransition: dispatch)
        case .dash(let dir, let res):
            await LocomotionBehaviors.runDashPhase(context: context, preferredDirection: dir, resolution: res, onTransition: dispatch)
        case .crouch(let dir, let origin):
            await RestBehaviors.runCrouchPhase(context: context, preferredFacingRight: dir, origin: origin, onTransition: dispatch)
        case .hop(let dir, let origin):
            await AerialBehaviors.runHopPhase(context: context, preferredDirection: dir, origin: origin, onTransition: dispatch)
        case .sit:
            await RestBehaviors.runSitPhase(context: context, onTransition: dispatch)
        case .lieDown:
            await RestBehaviors.runLieDownPhase(context: context, onTransition: dispatch)
        case .sleep:
            await RestBehaviors.runSleepPhase(context: context)
        case .attack:
            await RestBehaviors.runAttackPhase(context: context, onTransition: dispatch)
        case .fright:
            await RestBehaviors.runFrightPhase(context: context, onTransition: dispatch)
        case .walkCooldown(let dir):
            await LocomotionBehaviors.runWalkCooldownPhase(context: context, goRight: dir)
        }
    }
}
