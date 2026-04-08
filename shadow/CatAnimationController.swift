import AppKit
import Combine
import SwiftUI

/// Drives a CatAnimationClip as a state-driven idle behavior.
///
/// Playback loop:
///   1. Show the rest frame.
///   2. Wait a randomized idle pause (the cat "exists" between blinks).
///   3. Advance through all frames at their per-frame durations.
///   4. Return to step 1.
///
/// To add future states (walk, sit, sleep), call `play(_:)` with a new clip.
/// The controller swaps clips cleanly without any caller needing to know about timing.
@MainActor
final class CatAnimationController: ObservableObject {

    /// The frame currently visible on screen. Drives the SwiftUI view.
    @Published private(set) var currentFrame: NSImage?

    // MARK: - Private state

    private var activeClip: CatAnimationClip
    private var playbackTask: Task<Void, Never>?

    // MARK: - Init

    init(clip: CatAnimationClip) {
        self.activeClip = clip
        self.currentFrame = clip.frames[safe: clip.restFrameIndex]
        startLoop()
    }

    deinit {
        playbackTask?.cancel()
    }

    // MARK: - Public API

    /// Swap in a new clip and restart the idle loop from its rest frame.
    /// Designed for future state transitions: `controller.play(.walk)`
    func play(_ clip: CatAnimationClip) {
        activeClip = clip
        currentFrame = clip.frames[safe: clip.restFrameIndex]
        startLoop()
    }

    // MARK: - Private

    private func startLoop() {
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            await self?.runIdleLoop()
        }
    }

    private func runIdleLoop() async {
        let clip = activeClip

        while !Task.isCancelled {

            // Step 1 — Rest on the neutral frame.
            currentFrame = clip.frames[safe: clip.restFrameIndex]

            // Step 2 — Randomized idle pause. Cat is alive but still between blinks.
            let pause = TimeInterval.random(
                in: CatAnimationConfig.idlePauseMin...CatAnimationConfig.idlePauseMax
            )
            do { try await Task.sleep(for: .seconds(pause)) }
            catch { return }

            // Step 3 — Play through every frame in order.
            for index in 0..<clip.frameCount {
                guard !Task.isCancelled else { return }
                currentFrame = clip.frames[safe: index]
                let duration = clip.frameDurations[safe: index] ?? 0.1
                do { try await Task.sleep(for: .seconds(duration)) }
                catch { return }
            }

            // Return to step 1.
        }
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
