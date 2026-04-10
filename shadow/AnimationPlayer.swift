import AppKit
import SwiftUI

/// Handles the mechanics of frame-by-frame animation playback and window movement.
/// Decouples "how to play an animation" from "why the cat is doing it".
@MainActor
final class AnimationPlayer {
    private let context: CatBehaviorContext

    init(context: CatBehaviorContext) {
        self.context = context
    }

    /// Advances through every frame of `clip` at each frame's configured duration.
    func playClip(_ clip: CatAnimationClip) async {
        await playClip(clip, frames: 0..<clip.frameCount)
    }

    /// Plays a contiguous frame range from an existing clip using the clip's configured timing.
    func playClip(_ clip: CatAnimationClip, frames frameRange: some Sequence<Int>) async {
        for index in frameRange {
            guard !Task.isCancelled else { return }
            guard clip.frames.indices.contains(index) else { continue }
            
            context.updateFrame(clip.frames[index])
            let duration = clip.frameDurations[index]
            try? await Task.sleep(for: .seconds(duration))
        }
    }

    /// Moves the window while playing a looping animation.
    func playMovementEpisode(
        clip: CatAnimationClip,
        state: CatState,
        goRight: Bool,
        speed: CGFloat,
        duration: TimeInterval
    ) async {
        context.updateState(state)
        context.updateFacingRight(goRight)

        let deadline = Date().addingTimeInterval(duration)

        movementLoop: while !Task.isCancelled, Date() < deadline {
            for index in 0..<clip.frameCount {
                guard !Task.isCancelled, Date() < deadline else { break movementLoop }

                context.updateFrame(clip.frames[index])

                let frameDuration = clip.frameDurations[index]
                let dx = speed * CGFloat(frameDuration) * (goRight ? 1 : -1)

                if !context.motionProxy.move(dx: dx) {
                    break movementLoop
                }

                try? await Task.sleep(for: .seconds(frameDuration))
            }
        }
    }

    /// Plays a sequence of frames with specific vertical offsets (for jumps/falls).
    func playAerialClip(
        clip: CatAnimationClip,
        state: CatState,
        goRight: Bool,
        frameIndices: [Int],
        verticalOffsets: [CGFloat],
        speed: CGFloat
    ) async {
        context.updateState(state)
        context.updateFacingRight(goRight)

        for (stepIndex, frameIndex) in frameIndices.enumerated() {
            guard !Task.isCancelled else { return }
            guard clip.frames.indices.contains(frameIndex) else { continue }

            context.updateFrame(clip.frames[frameIndex])
            context.updateVerticalOffset(verticalOffsets[safe: stepIndex] ?? 0)

            let frameDuration = clip.frameDurations[frameIndex]
            let dx = speed * CGFloat(frameDuration) * (goRight ? 1 : -1)
            context.motionProxy.move(dx: dx)

            try? await Task.sleep(for: .seconds(frameDuration))
        }
    }

    /// Plays a single-shot movement clip (like a dash).
    func playMovementClipOnce(
        clip: CatAnimationClip,
        state: CatState,
        goRight: Bool,
        speed: CGFloat
    ) async {
        context.updateState(state)
        context.updateFacingRight(goRight)

        for index in 0..<clip.frameCount {
            guard !Task.isCancelled else { return }

            context.updateFrame(clip.frames[index])

            let frameDuration = clip.frameDurations[index]
            let dx = speed * CGFloat(frameDuration) * (goRight ? 1 : -1)

            if !context.motionProxy.move(dx: dx) {
                return
            }

            try? await Task.sleep(for: .seconds(frameDuration))
        }
    }
    
    /// Specialized helper for wall-based aerial movements (climb/drop).
    func playWallAerialPhase(
        clip: CatAnimationClip,
        state: CatState,
        goRight: Bool,
        frameIndices: [Int],
        spriteVerticalOffsets: [CGFloat],
        windowVerticalMoves: [CGFloat],
        horizontalSpeed: CGFloat
    ) async {
        context.updateState(state)
        context.updateFacingRight(goRight)

        for (stepIndex, frameIndex) in frameIndices.enumerated() {
            guard !Task.isCancelled else { return }
            guard clip.frames.indices.contains(frameIndex) else { continue }

            context.updateFrame(clip.frames[frameIndex])
            context.updateVerticalOffset(spriteVerticalOffsets[safe: stepIndex] ?? 0)

            let frameDuration = clip.frameDurations[frameIndex]
            let dx = horizontalSpeed * CGFloat(frameDuration) * (goRight ? 1 : -1)
            context.motionProxy.move(dx: dx)

            let dy = windowVerticalMoves[safe: stepIndex] ?? 0
            context.motionProxy.move(dy: dy)

            try? await Task.sleep(for: .seconds(frameDuration))
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
