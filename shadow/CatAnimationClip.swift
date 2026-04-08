import AppKit

/// An immutable, named animation sequence ready to be driven by a CatAnimationController.
/// Knows nothing about timing policies or idle behavior — that lives in the controller.
struct CatAnimationClip {

    /// Human-readable identifier used for debugging and future state-machine transitions.
    /// Examples: "idle", "idleBlink", "walk", "sit", "sleep"
    let name: String

    /// Ordered sequence of frames for this clip.
    let frames: [NSImage]

    /// Per-frame hold duration in seconds. Must equal `frames.count`.
    let frameDurations: [TimeInterval]

    /// Index of the frame treated as the neutral/rest pose.
    let restFrameIndex: Int

    var frameCount: Int { frames.count }
}

// MARK: - Built-in clips

extension CatAnimationClip {

    /// Subtle looping body animation — the default resting state.
    static let idle: CatAnimationClip = {
        let frames = CatSpriteLoader.loadStrip(
            assetName: CatAnimationConfig.idleAsset,
            frameCount: CatAnimationConfig.idleFrameCount
        )
        return CatAnimationClip(
            name: "idle",
            frames: frames,
            frameDurations: CatAnimationConfig.idleFrameDurations,
            restFrameIndex: 0
        )
    }()

    /// Single blink cycle, layered into idle as a variation.
    static let idleBlink: CatAnimationClip = {
        let frames = CatSpriteLoader.loadStrip(
            assetName: CatAnimationConfig.idleBlinkAsset,
            frameCount: CatAnimationConfig.idleBlinkFrameCount
        )
        return CatAnimationClip(
            name: "idleBlink",
            frames: frames,
            frameDurations: CatAnimationConfig.idleBlinkFrameDurations,
            restFrameIndex: 0
        )
    }()
}
