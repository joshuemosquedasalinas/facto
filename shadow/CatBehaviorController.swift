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

    // MARK: - Private state

    private(set) var state: CatState = .idle
    private weak var motionProxy: WindowMotionProxy?
    private var behaviorTask: Task<Void, Never>?

    // MARK: - Lifecycle

    deinit { behaviorTask?.cancel() }

    /// Call once from ContentView.onAppear after the window is ready.
    func start(motionProxy: WindowMotionProxy) {
        self.motionProxy = motionProxy
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
            } else if roll < (CatAnimationConfig.lieDownChance + CatAnimationConfig.sitChance) {
                await runSitPhase()
            } else if roll < (CatAnimationConfig.lieDownChance
                + CatAnimationConfig.sitChance
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
        // Choose direction, respecting screen edges.
        let goRight: Bool
        if let proxy = motionProxy {
            if proxy.isAtRightEdge      { goRight = false }
            else if proxy.isAtLeftEdge  { goRight = true  }
            else                        { goRight = Bool.random() }
        } else {
            goRight = Bool.random()
        }

        state       = goRight ? .walkRight : .walkLeft
        facingRight = goRight

        let walkDuration = TimeInterval.random(
            in: CatAnimationConfig.walkDurationMin...CatAnimationConfig.walkDurationMax
        )
        let deadline = Date().addingTimeInterval(walkDuration)
        let clip     = CatAnimationClip.walk

        walkLoop: while !Task.isCancelled, Date() < deadline {
            for index in 0..<clip.frameCount {
                guard !Task.isCancelled, Date() < deadline else { break walkLoop }

                currentFrame = clip.frames[safe: index]

                let frameDuration = clip.frameDurations[safe: index] ?? 0.1
                let dx = CatAnimationConfig.walkSpeed * CGFloat(frameDuration) * (goRight ? 1 : -1)

                // Move window; stop if we hit an edge.
                if let proxy = motionProxy, !proxy.move(dx: dx) {
                    break walkLoop
                }

                do { try await Task.sleep(for: .seconds(frameDuration)) } catch { return }
            }
        }

        // Snap back to idle rest frame before re-entering idle phase.
        state       = .idle
        facingRight = true
        currentFrame = CatAnimationClip.idle.frames[safe: 0]
    }

    // MARK: - Sit phase

    private func runSitPhase() async {
        state = .sit
        let cycles = Int.random(in: CatAnimationConfig.sitCyclesMin...CatAnimationConfig.sitCyclesMax)

        for _ in 0..<cycles {
            guard !Task.isCancelled else { return }
            await playClip(.sit)
        }

        if Double.random(in: 0..<1) < CatAnimationConfig.lieDownFromSitChance {
            await runLieDownPhase()
            return
        }

        // Occasionally transition to blink before returning to idle
        if Double.random(in: 0..<1) < CatAnimationConfig.blinkVariationChance {
            await playClip(.idleBlink)
        }

        state = .idle
        currentFrame = CatAnimationClip.idle.frames[safe: 0]
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
