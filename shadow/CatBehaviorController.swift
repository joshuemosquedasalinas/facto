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

            if Double.random(in: 0..<1) < CatAnimationConfig.walkChance {
                await runWalkPhase()
                guard !Task.isCancelled else { return }
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

    // MARK: - Animation playback

    /// Advances through every frame of `clip` at each frame's configured duration.
    /// Pure playback — no state changes, no movement.
    private func playClip(_ clip: CatAnimationClip) async {
        for index in 0..<clip.frameCount {
            guard !Task.isCancelled else { return }
            currentFrame = clip.frames[safe: index]
            let duration = clip.frameDurations[safe: index] ?? 0.1
            do { try await Task.sleep(for: .seconds(duration)) } catch { return }
        }
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
