import AppKit
import Combine
import SwiftUI

/// Drives a primary CatAnimationClip with an optional variation clip layered in.
///
/// Playback loop:
///   1. Play the primary clip through once.
///   2. Short randomized pause.
///   3. If a variation clip is configured and the random roll passes, play it once.
///   4. Return to step 1.
///
/// To add future states (walk, sit, sleep), call `play(_:)` with a new primary clip.
@MainActor
final class CatAnimationController: ObservableObject {

    /// The frame currently visible on screen.
    @Published private(set) var currentFrame: NSImage?

    // MARK: - Private state

    private var primaryClip: CatAnimationClip
    private var variationClip: CatAnimationClip?
    private var variationChance: Double
    private var playbackTask: Task<Void, Never>?

    // MARK: - Init

    /// - Parameters:
    ///   - primary: The main looping clip (e.g. `.idle`).
    ///   - variation: An optional clip injected at random intervals (e.g. `.idleBlink`).
    ///   - variationChance: Probability per cycle that the variation plays (0–1).
    init(
        primary: CatAnimationClip,
        variation: CatAnimationClip? = nil,
        variationChance: Double = 0
    ) {
        self.primaryClip    = primary
        self.variationClip  = variation
        self.variationChance = variationChance
        self.currentFrame   = primary.frames[safe: primary.restFrameIndex]
        startLoop()
    }

    deinit { playbackTask?.cancel() }

    // MARK: - Public API

    /// Swap to a new primary clip and optionally a new variation.
    /// Designed for future state transitions: `controller.play(.walk)`.
    func play(
        _ clip: CatAnimationClip,
        variation: CatAnimationClip? = nil,
        variationChance: Double = 0
    ) {
        primaryClip     = clip
        variationClip   = variation
        self.variationChance = variationChance
        currentFrame    = clip.frames[safe: clip.restFrameIndex]
        startLoop()
    }

    // MARK: - Private

    private func startLoop() {
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            await self?.runLoop()
        }
    }

    private func runLoop() async {
        while !Task.isCancelled {

            // Step 1 — play the primary clip (e.g. idle body loop).
            await playClip(primaryClip)
            guard !Task.isCancelled else { return }

            // Step 2 — short pause between primary cycles.
            let pause = TimeInterval.random(
                in: CatAnimationConfig.idleLoopPauseMin...CatAnimationConfig.idleLoopPauseMax
            )
            do { try await Task.sleep(for: .seconds(pause)) }
            catch { return }

            // Step 3 — occasionally inject the variation (e.g. idleBlink).
            if let variation = variationClip,
               Double.random(in: 0..<1) < variationChance {
                await playClip(variation)
                guard !Task.isCancelled else { return }
            }

            // Step 4 — back to step 1.
        }
    }

    /// Advances through every frame of `clip` at each frame's configured duration.
    private func playClip(_ clip: CatAnimationClip) async {
        for index in 0..<clip.frameCount {
            guard !Task.isCancelled else { return }
            currentFrame = clip.frames[safe: index]
            let duration = clip.frameDurations[safe: index] ?? 0.1
            do { try await Task.sleep(for: .seconds(duration)) }
            catch { return }
        }
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
