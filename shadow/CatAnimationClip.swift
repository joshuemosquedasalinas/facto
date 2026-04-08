import AppKit

/// An immutable, named animation sequence ready to be driven by a behavior controller.
struct CatAnimationClip {

    /// Human-readable identifier. Examples: "idle", "idleBlink", "walk", "sit", "sleep"
    let name: String

    /// Ordered sequence of frames.
    let frames: [NSImage]

    /// Per-frame hold duration in seconds. Must equal `frames.count`.
    let frameDurations: [TimeInterval]

    var frameCount: Int { frames.count }
}

// MARK: - Built-in clips

extension CatAnimationClip {

    /// Subtle looping body animation — the default resting state.
    static let idle: CatAnimationClip = {
        CatAnimationClip(
            name: "idle",
            frames: CatSpriteLoader.loadStrip(
                assetName: CatAnimationConfig.idleAsset,
                frameCount: CatAnimationConfig.idleFrameCount
            ),
            frameDurations: CatAnimationConfig.idleFrameDurations
        )
    }()

    /// Single blink cycle — layered into idle as a variation.
    static let idleBlink: CatAnimationClip = {
        CatAnimationClip(
            name: "idleBlink",
            frames: CatSpriteLoader.loadStrip(
                assetName: CatAnimationConfig.idleBlinkAsset,
                frameCount: CatAnimationConfig.idleBlinkFrameCount
            ),
            frameDurations: CatAnimationConfig.idleBlinkFrameDurations
        )
    }()

    /// Walk cycle — sprite faces right by default; flip horizontally for leftward movement.
    static let walk: CatAnimationClip = {
        CatAnimationClip(
            name: "walk",
            frames: CatSpriteLoader.loadStrip(
                assetName: CatAnimationConfig.walkAsset,
                frameCount: CatAnimationConfig.walkFrameCount
            ),
            frameDurations: CatAnimationConfig.walkFrameDurations
        )
    }()

    /// Sneak cycle — low-profile crawl used for calm, deliberate movement.
    static let sneak: CatAnimationClip = {
        CatAnimationClip(
            name: "sneak",
            frames: CatSpriteLoader.loadStrip(
                assetName: CatAnimationConfig.sneakAsset,
                frameCount: CatAnimationConfig.sneakFrameCount
            ),
            frameDurations: CatAnimationConfig.sneakFrameDurations
        )
    }()

    /// Run cycle — higher-energy locomotion burst.
    static let run: CatAnimationClip = {
        CatAnimationClip(
            name: "run",
            frames: CatSpriteLoader.loadStrip(
                assetName: CatAnimationConfig.runAsset,
                frameCount: CatAnimationConfig.runFrameCount
            ),
            frameDurations: CatAnimationConfig.runFrameDurations
        )
    }()

    /// Dash burst — ultra-short, one-shot zoomie clip.
    static let dash: CatAnimationClip = {
        CatAnimationClip(
            name: "dash",
            frames: CatSpriteLoader.loadStrip(
                assetName: CatAnimationConfig.dashAsset,
                frameCount: CatAnimationConfig.dashFrameCount
            ),
            frameDurations: CatAnimationConfig.dashFrameDurations
        )
    }()

    /// Sit cycle — temporary resting behavior.
    static let sit: CatAnimationClip = {
        CatAnimationClip(
            name: "sit",
            frames: CatSpriteLoader.loadStrip(
                assetName: CatAnimationConfig.sitAsset,
                frameCount: CatAnimationConfig.sitFrameCount
            ),
            frameDurations: CatAnimationConfig.sitFrameDurations
        )
    }()

    /// Lie-down transition — played once, then held briefly by behavior logic.
    static let lieDown: CatAnimationClip = {
        CatAnimationClip(
            name: "lieDown",
            frames: CatSpriteLoader.loadStrip(
                assetName: CatAnimationConfig.lieDownAsset,
                frameCount: CatAnimationConfig.lieDownFrameCount
            ),
            frameDurations: CatAnimationConfig.lieDownFrameDurations
        )
    }()

    /// Sleep cycle — looping rest state.
    static let sleep: CatAnimationClip = {
        CatAnimationClip(
            name: "sleep",
            frames: CatSpriteLoader.loadStrip(
                assetName: CatAnimationConfig.sleepAsset,
                frameCount: CatAnimationConfig.sleepFrameCount
            ),
            frameDurations: CatAnimationConfig.sleepFrameDurations
        )
    }()
}
