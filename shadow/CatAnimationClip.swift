import AppKit

/// An immutable, named animation sequence ready to be driven by a CatAnimationController.
/// Knows nothing about timing policies or idle behavior — that lives in the controller.
struct CatAnimationClip {

    /// Human-readable identifier used for debugging and future state-machine transitions.
    /// Examples: "idleBlink", "walk", "sit", "sleep"
    let name: String

    /// Ordered sequence of frames for this clip.
    let frames: [NSImage]

    /// Per-frame hold duration in seconds. Must equal `frames.count`.
    let frameDurations: [TimeInterval]

    /// Index of the frame treated as the neutral/rest pose.
    /// The controller shows this frame during idle pauses between cycles.
    let restFrameIndex: Int

    var frameCount: Int { frames.count }
}

// MARK: - Built-in clips

extension CatAnimationClip {

    /// The primary idle + blink animation. Loaded once at app start.
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
