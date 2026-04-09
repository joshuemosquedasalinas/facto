import AppKit
import Combine

/// Top-level controller that owns the cat's state machine, animation playback, and movement.
///
/// Separation of concerns:
///   - Asset loading       → CatSpriteLoader
///   - Clip definitions    → CatAnimationClip + CatAnimationConfig
///   - Animation playback  → playClip(_:) — advances frames at per-frame durations
///   - State/behavior      → runBehaviorLoop() — decides idle vs walk, timing, variation
///   - Movement            → WindowMotionProxy.move(dx:)
///
/// To add future states: extend CatState, add a run___Phase() method, wire into runBehaviorLoop().
@MainActor
final class CatBehaviorController: ObservableObject {

    /// Current animation frame for display.
    @Published private(set) var currentFrame: NSImage?

    /// Whether the sprite should face right. CatView flips horizontally when false.
    @Published private(set) var facingRight: Bool = true

    /// Sprite-space vertical offset used for short aerial arcs without moving the whole window vertically.
    @Published private(set) var verticalOffset: CGFloat = 0

    // MARK: - Private state

    private(set) var state: CatState = .idle
    private weak var motionProxy: WindowMotionProxy?
    private var behaviorTask: Task<Void, Never>?

    // MARK: - Lifecycle

    deinit { behaviorTask?.cancel() }

    /// Call once from ContentView.onAppear after the window is ready.
    func start(motionProxy: WindowMotionProxy) {
        self.motionProxy = motionProxy
        verticalOffset = 0
        behaviorTask?.cancel()
        behaviorTask = Task { [weak self] in
            await self?.runBehaviorLoop()
        }
    }

    // MARK: - Top-level behavior loop

    private func runBehaviorLoop() async {
        // Seed the display with the idle rest frame immediately.
        currentFrame = CatAnimationClip.idle.frames[safe: 0]

        while !Task.isCancelled {
            await runIdlePhase()
            guard !Task.isCancelled else { return }

            let roll = Double.random(in: 0..<1)
            if roll < CatAnimationConfig.lieDownChance {
                await runLieDownPhase()
            } else if roll < (CatAnimationConfig.lieDownChance
                + CatAnimationConfig.crouchChance) {
                await runCrouchPhase()
            } else if roll < (CatAnimationConfig.lieDownChance
                + CatAnimationConfig.crouchChance
                + CatAnimationConfig.sitChance) {
                await runSitPhase()
            } else if roll < (CatAnimationConfig.lieDownChance
                + CatAnimationConfig.crouchChance
                + CatAnimationConfig.sitChance
                + CatAnimationConfig.sneakChance) {
                await runSneakPhase()
            } else if roll < (CatAnimationConfig.lieDownChance
                + CatAnimationConfig.crouchChance
                + CatAnimationConfig.sitChance
                + CatAnimationConfig.sneakChance
                + CatAnimationConfig.hopChance) {
                await runHopPhase(preferredDirection: nil, origin: .idle)
            } else if roll < (CatAnimationConfig.lieDownChance
                + CatAnimationConfig.crouchChance
                + CatAnimationConfig.sitChance
                + CatAnimationConfig.sneakChance
                + CatAnimationConfig.hopChance
                + CatAnimationConfig.runChance) {
                await runRunPhase()
            } else if roll < (CatAnimationConfig.lieDownChance
                + CatAnimationConfig.crouchChance
                + CatAnimationConfig.sitChance
                + CatAnimationConfig.sneakChance
                + CatAnimationConfig.hopChance
                + CatAnimationConfig.runChance
                + CatAnimationConfig.dashChance) {
                await runDashPhase()
            } else if roll < (CatAnimationConfig.lieDownChance
                + CatAnimationConfig.crouchChance
                + CatAnimationConfig.sitChance
                + CatAnimationConfig.sneakChance
                + CatAnimationConfig.hopChance
                + CatAnimationConfig.runChance
                + CatAnimationConfig.dashChance
                + CatAnimationConfig.wallGrabChance) {
                // Wall behavior only fires when the cat is already pressed against an edge.
                if motionProxy?.isAtLeftEdge == true || motionProxy?.isAtRightEdge == true {
                    await runWallBehaviorPhase()
                }
            } else if roll < (CatAnimationConfig.lieDownChance
                + CatAnimationConfig.crouchChance
                + CatAnimationConfig.sitChance
                + CatAnimationConfig.sneakChance
                + CatAnimationConfig.hopChance
                + CatAnimationConfig.runChance
                + CatAnimationConfig.dashChance
                + CatAnimationConfig.wallGrabChance
                + CatAnimationConfig.walkChance) {
                await runWalkPhase()
            }
        }
    }

    // MARK: - Idle phase

    private func runIdlePhase() async {
        state = .idle
        let cycles = Int.random(in: CatAnimationConfig.idleCyclesMin...CatAnimationConfig.idleCyclesMax)

        for _ in 0..<cycles {
            guard !Task.isCancelled else { return }

            await playClip(.idle)
            guard !Task.isCancelled else { return }

            // Short pause between idle loops.
            let pause = TimeInterval.random(
                in: CatAnimationConfig.idleLoopPauseMin...CatAnimationConfig.idleLoopPauseMax
            )
            do { try await Task.sleep(for: .seconds(pause)) } catch { return }

            // Occasionally insert a blink.
            if Double.random(in: 0..<1) < CatAnimationConfig.blinkVariationChance {
                await playClip(.idleBlink)
            }
        }
    }

    // MARK: - Walk phase

    private func runWalkPhase() async {
        guard let goRight = chooseMovementDirection(preferredDirection: nil) else { return }

        let walkDuration = TimeInterval.random(
            in: CatAnimationConfig.walkDurationMin...CatAnimationConfig.walkDurationMax
        )
        await runMovementEpisode(
            clip: .walk,
            state: goRight ? .walkRight : .walkLeft,
            goRight: goRight,
            speed: CatAnimationConfig.walkSpeed,
            duration: walkDuration
        )
        guard !Task.isCancelled else { return }

        let transitionRoll = Double.random(in: 0..<1)
        if transitionRoll < CatAnimationConfig.walkToHopChance {
            await runHopPhase(preferredDirection: goRight, origin: .walk)
            return
        }

        if transitionRoll < (CatAnimationConfig.walkToHopChance + CatAnimationConfig.walkToDashChance) {
            await runDashPhase(preferredDirection: goRight, resolution: .walk)
            return
        }

        if transitionRoll < (CatAnimationConfig.walkToHopChance
            + CatAnimationConfig.walkToDashChance
            + CatAnimationConfig.walkToRunChance) {
            await runRunPhase(preferredDirection: goRight, allowWalkCooldown: true)
            return
        }

        if transitionRoll < (CatAnimationConfig.walkToHopChance
            + CatAnimationConfig.walkToDashChance
            + CatAnimationConfig.walkToRunChance
            + CatAnimationConfig.walkToCrouchChance) {
            await runCrouchPhase(preferredFacingRight: goRight, origin: .walk)
            return
        }

        // Snap back to idle rest frame before re-entering idle phase.
        settleToIdle()
    }

    // MARK: - Crouch phase

    private func runCrouchPhase(
        preferredFacingRight: Bool? = nil,
        origin: CrouchOrigin = .idle
    ) async {
        state = .crouch
        if let preferredFacingRight {
            facingRight = preferredFacingRight
        }

        await playClip(.crouch)
        guard !Task.isCancelled else { return }

        currentFrame = CatAnimationClip.crouch.frames.last
        let holdDuration = TimeInterval.random(
            in: CatAnimationConfig.crouchHoldMin...CatAnimationConfig.crouchHoldMax
        )
        do { try await Task.sleep(for: .seconds(holdDuration)) } catch { return }
        guard !Task.isCancelled else { return }

        let roll = Double.random(in: 0..<1)

        switch origin {
        case .idle, .walk:
            if roll < CatAnimationConfig.crouchToHopChance {
                await runHopPhase(preferredDirection: facingRight, origin: .crouch)
            } else if roll < (CatAnimationConfig.crouchToHopChance + CatAnimationConfig.crouchToSneakChance) {
                await runSneakPhase(preferredDirection: facingRight, origin: .crouch)
            } else if roll < (CatAnimationConfig.crouchToHopChance
                + CatAnimationConfig.crouchToSneakChance
                + CatAnimationConfig.crouchToLieDownChance) {
                await runLieDownPhase()
            } else if roll < (CatAnimationConfig.crouchToHopChance
                + CatAnimationConfig.crouchToSneakChance
                + CatAnimationConfig.crouchToLieDownChance
                + CatAnimationConfig.crouchToSitChance) {
                await runSitPhase()
            } else {
                settleToIdle()
            }
        case .sit:
            if roll < 0.35 {
                await runSneakPhase(preferredDirection: facingRight, origin: .crouch)
            } else {
                settleToIdle()
            }
        case .lieDown:
            if roll < 0.55 {
                await runSneakPhase(preferredDirection: facingRight, origin: .crouch)
            } else if roll < 0.80 {
                state = .sit
                await playClip(.sit)
                settleToIdle()
            } else {
                settleToIdle()
            }
        case .sneak:
            if roll < 0.35 {
                await runLieDownPhase()
            } else if roll < 0.65 {
                state = .sit
                await playClip(.sit)
                settleToIdle()
            } else {
                settleToIdle()
            }
        }
    }

    // MARK: - Sneak phase

    private func runSneakPhase(
        preferredDirection: Bool? = nil,
        origin: SneakOrigin = .idle
    ) async {
        guard let goRight = chooseMovementDirection(preferredDirection: preferredDirection) else { return }

        let duration = TimeInterval.random(
            in: CatAnimationConfig.sneakDurationMin...CatAnimationConfig.sneakDurationMax
        )
        await runMovementEpisode(
            clip: .sneak,
            state: goRight ? .sneakRight : .sneakLeft,
            goRight: goRight,
            speed: CatAnimationConfig.sneakSpeed,
            duration: duration
        )
        guard !Task.isCancelled else { return }

        let roll = Double.random(in: 0..<1)

        switch origin {
        case .idle:
            if roll < CatAnimationConfig.sneakToHopChance {
                await runHopPhase(preferredDirection: goRight, origin: .sneak)
            } else if roll < (CatAnimationConfig.sneakToHopChance + CatAnimationConfig.sneakToWalkChance) {
                await runWalkCooldownPhase(goRight: goRight)
            } else if roll < (CatAnimationConfig.sneakToHopChance
                + CatAnimationConfig.sneakToWalkChance
                + CatAnimationConfig.sneakToSitChance) {
                await runSitPhase()
            } else if roll < (CatAnimationConfig.sneakToHopChance
                + CatAnimationConfig.sneakToWalkChance
                + CatAnimationConfig.sneakToSitChance
                + CatAnimationConfig.sneakToLieDownChance) {
                await runLieDownPhase()
            } else {
                settleToIdle()
            }
        case .sit:
            if roll < 0.45 {
                await runCrouchPhase(preferredFacingRight: goRight, origin: .sneak)
            } else if roll < 0.80 {
                await runSitPhase()
            } else {
                await runLieDownPhase()
            }
        case .lieDown:
            if roll < 0.50 {
                await runCrouchPhase(preferredFacingRight: goRight, origin: .sneak)
            } else if roll < 0.75 {
                await runLieDownPhase()
            } else {
                await runSitPhase()
            }
        case .crouch:
            if roll < 0.45 {
                await runCrouchPhase(preferredFacingRight: goRight, origin: .sneak)
            } else if roll < 0.75 {
                await runLieDownPhase()
            } else {
                await runSitPhase()
            }
        }
    }

    // MARK: - Run phase

    private func runRunPhase(preferredDirection: Bool? = nil, allowWalkCooldown: Bool = false) async {
        guard let goRight = chooseMovementDirection(preferredDirection: preferredDirection) else { return }

        let runDuration = TimeInterval.random(
            in: CatAnimationConfig.runDurationMin...CatAnimationConfig.runDurationMax
        )
        await runMovementEpisode(
            clip: .run,
            state: goRight ? .runRight : .runLeft,
            goRight: goRight,
            speed: CatAnimationConfig.runSpeed,
            duration: runDuration
        )
        guard !Task.isCancelled else { return }

        let resolutionRoll = Double.random(in: 0..<1)
        if resolutionRoll < CatAnimationConfig.runToHopChance {
            await runHopPhase(preferredDirection: goRight, origin: .run)
        } else if resolutionRoll < (CatAnimationConfig.runToHopChance + CatAnimationConfig.runToDashChance) {
            await runDashPhase(preferredDirection: goRight, resolution: .run)
        } else if allowWalkCooldown, resolutionRoll < (CatAnimationConfig.runToHopChance
            + CatAnimationConfig.runToDashChance
            + CatAnimationConfig.runToWalkChance) {
            await runWalkCooldownPhase(goRight: goRight)
        } else if resolutionRoll < (CatAnimationConfig.runToHopChance
            + CatAnimationConfig.runToDashChance
            + CatAnimationConfig.runToWalkChance
            + CatAnimationConfig.runToSitChance) {
            await runSitPhase()
        } else {
            settleToIdle()
        }
    }

    // MARK: - Hop phase

    private func runHopPhase(
        preferredDirection: Bool? = nil,
        origin: HopOrigin = .idle
    ) async {
        guard let goRight = chooseMovementDirection(preferredDirection: preferredDirection) else { return }

        let useExtendedFall = Double.random(in: 0..<1) < CatAnimationConfig.extendedFallChance
        let fallIndices = useExtendedFall
            ? CatAnimationConfig.extendedFallFrameIndices
            : Array(0..<CatAnimationClip.fall.frameCount)
        let fallOffsets = useExtendedFall
            ? CatAnimationConfig.extendedFallVerticalOffsets
            : CatAnimationConfig.fallVerticalOffsets

        await playAerialClip(
            .jump,
            state: goRight ? .jumpRight : .jumpLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.jump.frameCount),
            verticalOffsets: CatAnimationConfig.jumpVerticalOffsets,
            speed: CatAnimationConfig.hopJumpSpeed
        )
        guard !Task.isCancelled else { return }

        await playAerialClip(
            .fall,
            state: goRight ? .fallRight : .fallLeft,
            goRight: goRight,
            frameIndices: fallIndices,
            verticalOffsets: fallOffsets,
            speed: CatAnimationConfig.hopFallSpeed
        )
        guard !Task.isCancelled else { return }

        await playAerialClip(
            .land,
            state: goRight ? .landRight : .landLeft,
            goRight: goRight,
            frameIndices: Array(0..<CatAnimationClip.land.frameCount),
            verticalOffsets: CatAnimationConfig.landVerticalOffsets,
            speed: CatAnimationConfig.hopLandSpeed
        )
        guard !Task.isCancelled else { return }

        verticalOffset = 0
        await resolveHopLanding(origin: origin, goRight: goRight)
    }

    // MARK: - Dash phase

    private func runDashPhase(
        preferredDirection: Bool? = nil,
        resolution: DashResolution = .idle
    ) async {
        guard let goRight = chooseMovementDirection(preferredDirection: preferredDirection) else { return }

        await playMovementClipOnce(
            clip: .dash,
            state: goRight ? .dashRight : .dashLeft,
            goRight: goRight,
            speed: CatAnimationConfig.dashSpeed
        )
        guard !Task.isCancelled else { return }

        switch resolution {
        case .walk:
            await runWalkCooldownPhase(goRight: goRight)
        case .run:
            let runDuration = TimeInterval.random(
                in: CatAnimationConfig.runDurationMin...CatAnimationConfig.runDurationMax
            )
            await runMovementEpisode(
                clip: .run,
                state: goRight ? .runRight : .runLeft,
                goRight: goRight,
                speed: CatAnimationConfig.runSpeed,
                duration: runDuration
            )
            guard !Task.isCancelled else { return }
            settleToIdle()
        case .idle:
            let roll = Double.random(in: 0..<1)
            if roll < CatAnimationConfig.dashFromIdleToWalkChance {
                await runWalkCooldownPhase(goRight: goRight)
            } else if roll < (CatAnimationConfig.dashFromIdleToWalkChance + CatAnimationConfig.dashFromIdleToRunChance) {
                await runRunPhase(preferredDirection: goRight, allowWalkCooldown: true)
            } else {
                settleToIdle()
            }
        }
    }

    private func runWalkCooldownPhase(goRight: Bool) async {
        let duration = TimeInterval.random(
            in: CatAnimationConfig.walkCooldownDurationMin...CatAnimationConfig.walkCooldownDurationMax
        )
        await runMovementEpisode(
            clip: .walk,
            state: goRight ? .walkRight : .walkLeft,
            goRight: goRight,
            speed: CatAnimationConfig.walkSpeed,
            duration: duration
        )
        guard !Task.isCancelled else { return }
        settleToIdle()
    }

    // MARK: - Sit phase

    private func runSitPhase() async {
        state = .sit
        let cycles = Int.random(in: CatAnimationConfig.sitCyclesMin...CatAnimationConfig.sitCyclesMax)

        for _ in 0..<cycles {
            guard !Task.isCancelled else { return }
            await playClip(.sit)
        }

        if Double.random(in: 0..<1) < CatAnimationConfig.sitToCrouchChance {
            await runCrouchPhase(preferredFacingRight: facingRight, origin: .sit)
            return
        }

        if Double.random(in: 0..<1) < CatAnimationConfig.sitToSneakChance {
            await runSneakPhase(origin: .sit)
            return
        }

        if Double.random(in: 0..<1) < CatAnimationConfig.lieDownFromSitChance {
            await runLieDownPhase()
            return
        }

        // Occasionally transition to blink before returning to idle
        if Double.random(in: 0..<1) < CatAnimationConfig.blinkVariationChance {
            await playClip(.idleBlink)
        }

        settleToIdle()
    }

    // MARK: - Lie-down phase

    private func runLieDownPhase() async {
        state = .lieDown

        let activeRange = CatAnimationConfig.lieDownActiveRange

        await playClip(.lieDown, frames: activeRange)
        guard !Task.isCancelled else { return }

        let restDuration = TimeInterval.random(
            in: CatAnimationConfig.lieDownRestMin...CatAnimationConfig.lieDownRestMax
        )
        let deadline = Date().addingTimeInterval(restDuration)

        while !Task.isCancelled, Date() < deadline {
            await playLieDownRestLoop()
            guard !Task.isCancelled else { return }

            let pause = TimeInterval.random(
                in: CatAnimationConfig.lieDownRestLoopPauseMin...CatAnimationConfig.lieDownRestLoopPauseMax
            )
            do { try await Task.sleep(for: .seconds(pause)) } catch { return }
        }

        guard !Task.isCancelled else { return }

        if Double.random(in: 0..<1) < CatAnimationConfig.lieDownToCrouchChance {
            await runCrouchPhase(preferredFacingRight: facingRight, origin: .lieDown)
            return
        }

        if Double.random(in: 0..<1) < CatAnimationConfig.lieDownToSneakChance {
            await runSneakPhase(origin: .lieDown)
            return
        }

        // Occasionally drift into a deep sleep after lying down.
        if Double.random(in: 0..<1) < CatAnimationConfig.sleepChance {
            await runSleepPhase()
            return
        }

        state = .sit
        for _ in 0..<CatAnimationConfig.lieDownExitSitCycles {
            guard !Task.isCancelled else { return }
            await playClip(.sit)
        }

        settleToIdle()
    }

    // MARK: - Wall behavior

    /// Entry point: determines which edge the cat is on, then runs grab → optional climb → resolve.
    private func runWallBehaviorPhase() async {
        guard let proxy = motionProxy else { return }

        // Determine facing: right edge → face right (into wall), left edge → face left (into wall).
        let goRight: Bool
        if proxy.isAtRightEdge {
            goRight = true
        } else if proxy.isAtLeftEdge {
            goRight = false
        } else {
            return
        }

        await runWallGrabPhase(goRight: goRight)
    }

    private func runWallGrabPhase(goRight: Bool) async {
        state = goRight ? .wallGrabRight : .wallGrabLeft
        facingRight = goRight

        let holdCycles = Int.random(
            in: CatAnimationConfig.wallGrabHoldCyclesMin...CatAnimationConfig.wallGrabHoldCyclesMax
        )
        for _ in 0..<holdCycles {
            guard !Task.isCancelled else { return }
            await playClip(.wallGrab)
        }
        guard !Task.isCancelled else { return }

        if Double.random(in: 0..<1) < CatAnimationConfig.wallGrabToClimbChance {
            await runWallClimbPhase(goRight: goRight)
        } else {
            settleToIdleFacing(goRight)
        }
    }

    private func runWallClimbPhase(goRight: Bool) async {
        state = goRight ? .wallClimbRight : .wallClimbLeft
        facingRight = goRight

        let duration = TimeInterval.random(
            in: CatAnimationConfig.wallClimbDurationMin...CatAnimationConfig.wallClimbDurationMax
        )
        let deadline = Date().addingTimeInterval(duration)

        climbLoop: while !Task.isCancelled, Date() < deadline {
            for index in 0..<CatAnimationClip.wallClimb.frameCount {
                guard !Task.isCancelled, Date() < deadline else { break climbLoop }

                currentFrame = CatAnimationClip.wallClimb.frames[safe: index]
                let frameDuration = CatAnimationClip.wallClimb.frameDurations[safe: index] ?? 0.1
                let dy = CatAnimationConfig.wallClimbSpeed * CGFloat(frameDuration)

                if let proxy = motionProxy, !proxy.move(dy: dy) {
                    // Reached the top edge — drop out cleanly.
                    break climbLoop
                }

                do { try await Task.sleep(for: .seconds(frameDuration)) } catch { return }
            }
        }
        guard !Task.isCancelled else { return }

        // After climbing: optionally re-grab, then resolve.
        if Double.random(in: 0..<1) < CatAnimationConfig.wallClimbToGrabChance {
            await runWallGrabPhase(goRight: goRight)
        } else {
            settleToIdleFacing(goRight)
        }
    }

    // MARK: - Locomotion

    private func chooseMovementDirection(preferredDirection: Bool?) -> Bool? {
        if let preferredDirection {
            if preferredDirection, motionProxy?.isAtRightEdge == true { return false }
            if !preferredDirection, motionProxy?.isAtLeftEdge == true { return true }
            return preferredDirection
        }

        if let proxy = motionProxy {
            if proxy.isAtRightEdge { return false }
            if proxy.isAtLeftEdge { return true }
        }

        return Bool.random()
    }

    private func runMovementEpisode(
        clip: CatAnimationClip,
        state newState: CatState,
        goRight: Bool,
        speed: CGFloat,
        duration: TimeInterval
    ) async {
        state = newState
        facingRight = goRight

        let deadline = Date().addingTimeInterval(duration)

        movementLoop: while !Task.isCancelled, Date() < deadline {
            for index in 0..<clip.frameCount {
                guard !Task.isCancelled, Date() < deadline else { break movementLoop }

                currentFrame = clip.frames[safe: index]

                let frameDuration = clip.frameDurations[safe: index] ?? 0.1
                let dx = speed * CGFloat(frameDuration) * (goRight ? 1 : -1)

                if let proxy = motionProxy, !proxy.move(dx: dx) {
                    break movementLoop
                }

                do { try await Task.sleep(for: .seconds(frameDuration)) } catch { return }
            }
        }
    }

    private func playAerialClip(
        _ clip: CatAnimationClip,
        state newState: CatState,
        goRight: Bool,
        frameIndices: [Int],
        verticalOffsets: [CGFloat],
        speed: CGFloat
    ) async {
        state = newState
        facingRight = goRight

        for (stepIndex, frameIndex) in frameIndices.enumerated() {
            guard !Task.isCancelled else { return }
            guard clip.frames.indices.contains(frameIndex) else { continue }

            currentFrame = clip.frames[safe: frameIndex]
            verticalOffset = verticalOffsets[safe: stepIndex] ?? 0

            let frameDuration = clip.frameDurations[safe: frameIndex] ?? 0.1
            let dx = speed * CGFloat(frameDuration) * (goRight ? 1 : -1)
            _ = motionProxy?.move(dx: dx)

            do { try await Task.sleep(for: .seconds(frameDuration)) } catch { return }
        }
    }

    private func playMovementClipOnce(
        clip: CatAnimationClip,
        state newState: CatState,
        goRight: Bool,
        speed: CGFloat
    ) async {
        state = newState
        facingRight = goRight

        for index in 0..<clip.frameCount {
            guard !Task.isCancelled else { return }

            currentFrame = clip.frames[safe: index]

            let frameDuration = clip.frameDurations[safe: index] ?? 0.1
            let dx = speed * CGFloat(frameDuration) * (goRight ? 1 : -1)

            if let proxy = motionProxy, !proxy.move(dx: dx) {
                return
            }

            do { try await Task.sleep(for: .seconds(frameDuration)) } catch { return }
        }
    }

    private func settleToIdle() {
        state = .idle
        facingRight = true
        verticalOffset = 0
        currentFrame = CatAnimationClip.idle.frames[safe: 0]
    }

    // MARK: - Sleep phase

    private func runSleepPhase() async {
        state = .sleep

        let sleepDuration = TimeInterval.random(
            in: CatAnimationConfig.sleepDurationMin...CatAnimationConfig.sleepDurationMax
        )
        let deadline = Date().addingTimeInterval(sleepDuration)

        // Continue looping the sleep animation for the duration.
        while !Task.isCancelled, Date() < deadline {
            await playClip(.sleep)
        }

        guard !Task.isCancelled else { return }

        // Waking up: hold the last frame briefly, then transition through sit to rise naturally.
        currentFrame = CatAnimationClip.sleep.frames.last
        do { try await Task.sleep(for: .seconds(0.6)) } catch { return }

        state = .sit
        for _ in 0..<CatAnimationConfig.lieDownExitSitCycles {
            guard !Task.isCancelled else { return }
            await playClip(.sit)
        }

        state = .idle
        currentFrame = CatAnimationClip.idle.frames[safe: 0]
    }

    private func playLieDownRestLoop() async {
        let clip = CatAnimationClip.lieDown
        let pattern = lieDownRestPatterns.randomElement() ?? []

        for index in pattern {
            guard !Task.isCancelled else { return }
            guard clip.frames.indices.contains(index) else { continue }

            currentFrame = clip.frames[safe: index]

            let duration: TimeInterval
            if lieDownStillFrames.contains(index) {
                duration = CatAnimationConfig.lieDownRestStillFrameDuration
            } else {
                duration = CatAnimationConfig.lieDownRestFrameDuration
            }

            do { try await Task.sleep(for: .seconds(duration)) } catch { return }
        }
    }

    private func resolveHopLanding(origin: HopOrigin, goRight: Bool) async {
        let roll = Double.random(in: 0..<1)

        switch origin {
        case .idle:
            if roll < CatAnimationConfig.hopFromIdleToWalkChance {
                await runWalkCooldownPhase(goRight: goRight)
            } else if roll < (CatAnimationConfig.hopFromIdleToWalkChance
                + CatAnimationConfig.hopFromIdleToCrouchChance) {
                await runCrouchPhase(preferredFacingRight: goRight, origin: .idle)
            } else {
                settleToIdleFacing(goRight)
            }
        case .walk:
            if roll < CatAnimationConfig.hopFromWalkToWalkChance {
                await runWalkCooldownPhase(goRight: goRight)
            } else if roll < (CatAnimationConfig.hopFromWalkToWalkChance
                + CatAnimationConfig.hopFromWalkToRunChance) {
                await runRunPhase(preferredDirection: goRight, allowWalkCooldown: true)
            } else {
                settleToIdleFacing(goRight)
            }
        case .run:
            if roll < CatAnimationConfig.hopFromRunToRunChance {
                await runRunPhase(preferredDirection: goRight, allowWalkCooldown: true)
            } else if roll < (CatAnimationConfig.hopFromRunToRunChance
                + CatAnimationConfig.hopFromRunToWalkChance) {
                await runWalkCooldownPhase(goRight: goRight)
            } else {
                settleToIdleFacing(goRight)
            }
        case .crouch:
            if roll < CatAnimationConfig.hopFromCrouchToCrouchChance {
                await runCrouchPhase(preferredFacingRight: goRight, origin: .idle)
            } else {
                settleToIdleFacing(goRight)
            }
        case .sneak:
            if roll < CatAnimationConfig.hopFromSneakToCrouchChance {
                await runCrouchPhase(preferredFacingRight: goRight, origin: .sneak)
            } else {
                settleToIdleFacing(goRight)
            }
        }
    }

    private func interpolatedOffsets(
        from start: CGFloat,
        to end: CGFloat,
        steps: Int
    ) -> [CGFloat] {
        guard steps > 1 else { return [end] }

        return (0..<steps).map { step in
            let progress = CGFloat(step + 1) / CGFloat(steps)
            return start + ((end - start) * progress)
        }
    }

    private func settleToIdleFacing(_ goRight: Bool) {
        state = .idle
        facingRight = goRight
        verticalOffset = 0
        currentFrame = CatAnimationClip.idle.frames[safe: 0]
    }

    // MARK: - Animation playback

    /// Advances through every frame of `clip` at each frame's configured duration.
    /// Pure playback — no state changes, no movement.
    private func playClip(_ clip: CatAnimationClip) async {
        await playClip(clip, frames: 0..<clip.frameCount)
    }

    /// Plays a contiguous frame range from an existing clip using the clip's configured timing.
    private func playClip(_ clip: CatAnimationClip, frames frameRange: some Sequence<Int>) async {
        for index in frameRange {
            guard !Task.isCancelled else { return }
            guard clip.frames.indices.contains(index) else { continue }
            currentFrame = clip.frames[safe: index]
            let duration = clip.frameDurations[safe: index] ?? 0.1
            do { try await Task.sleep(for: .seconds(duration)) } catch { return }
        }
    }
}

// MARK: - Safe array subscript

private let lieDownStillFrames: Set<Int> = [3, 4]

private let lieDownRestPatterns: [[Int]] = [
    [0, 1, 2, 3, 4, 4, 5, 6, 5, 4, 4, 3, 2, 1],
    [1, 2, 3, 3, 4, 4, 5, 5, 4, 4, 3, 2],
    [0, 1, 2, 3, 4, 4, 4, 5, 4, 3, 3, 2, 1],
    [1, 2, 3, 4, 4, 5, 6, 6, 5, 4, 4, 3, 2],
]

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private enum DashResolution {
    case idle
    case walk
    case run
}

private enum HopOrigin {
    case idle
    case walk
    case run
    case crouch
    case sneak
}

private enum SneakOrigin {
    case idle
    case sit
    case lieDown
    case crouch
}

private enum CrouchOrigin {
    case idle
    case walk
    case sit
    case lieDown
    case sneak
}
