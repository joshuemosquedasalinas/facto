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
                asset:CatAnimationConfig.Idle.asset,
                frameCount: CatAnimationConfig.Idle.frameCount
            ),
            frameDurations: CatAnimationConfig.Idle.frameDurations
        )
    }()

    /// Single blink cycle — layered into idle as a variation.
    static let idleBlink: CatAnimationClip = {
        CatAnimationClip(
            name: "idleBlink",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Idle.Blink.asset,
                frameCount: CatAnimationConfig.Idle.Blink.frameCount
            ),
            frameDurations: CatAnimationConfig.Idle.Blink.frameDurations
        )
    }()

    /// Walk cycle — sprite faces right by default; flip horizontally for leftward movement.
    static let walk: CatAnimationClip = {
        CatAnimationClip(
            name: "walk",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Walk.asset,
                frameCount: CatAnimationConfig.Walk.frameCount
            ),
            frameDurations: CatAnimationConfig.Walk.frameDurations
        )
    }()

    /// Sneak cycle — low-profile crawl used for calm, deliberate movement.
    static let sneak: CatAnimationClip = {
        CatAnimationClip(
            name: "sneak",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Sneak.asset,
                frameCount: CatAnimationConfig.Sneak.frameCount
            ),
            frameDurations: CatAnimationConfig.Sneak.frameDurations
        )
    }()

    /// Jump launch — one-shot takeoff clip for short hops.
    static let jump: CatAnimationClip = {
        CatAnimationClip(
            name: "jump",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Aerial.Jump.asset,
                frameCount: CatAnimationConfig.Aerial.Jump.frameCount
            ),
            frameDurations: CatAnimationConfig.Aerial.Jump.frameDurations
        )
    }()

    /// Fall descent — brief airborne bridge between launch and landing.
    static let fall: CatAnimationClip = {
        CatAnimationClip(
            name: "fall",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Aerial.Fall.asset,
                frameCount: CatAnimationConfig.Aerial.Fall.frameCount
            ),
            frameDurations: CatAnimationConfig.Aerial.Fall.frameDurations
        )
    }()

    /// Land recovery — one-shot touchdown that resolves back to grounded behavior.
    static let land: CatAnimationClip = {
        CatAnimationClip(
            name: "land",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Aerial.Land.asset,
                frameCount: CatAnimationConfig.Aerial.Land.frameCount
            ),
            frameDurations: CatAnimationConfig.Aerial.Land.frameDurations
        )
    }()

    /// Run cycle — higher-energy locomotion burst.
    static let run: CatAnimationClip = {
        CatAnimationClip(
            name: "run",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Run.asset,
                frameCount: CatAnimationConfig.Run.frameCount
            ),
            frameDurations: CatAnimationConfig.Run.frameDurations
        )
    }()

    /// Dash burst — ultra-short, one-shot zoomie clip.
    static let dash: CatAnimationClip = {
        CatAnimationClip(
            name: "dash",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Dash.asset,
                frameCount: CatAnimationConfig.Dash.frameCount
            ),
            frameDurations: CatAnimationConfig.Dash.frameDurations
        )
    }()

    /// Crouch posture — compressed low-to-the-ground calm state.
    static let crouch: CatAnimationClip = {
        CatAnimationClip(
            name: "crouch",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Crouch.asset,
                frameCount: CatAnimationConfig.Crouch.frameCount
            ),
            frameDurations: CatAnimationConfig.Crouch.frameDurations
        )
    }()

    /// Sit cycle — temporary resting behavior.
    static let sit: CatAnimationClip = {
        CatAnimationClip(
            name: "sit",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Sit.asset,
                frameCount: CatAnimationConfig.Sit.frameCount
            ),
            frameDurations: CatAnimationConfig.Sit.frameDurations
        )
    }()

    /// Lie-down transition — played once, then held briefly by behavior logic.
    static let lieDown: CatAnimationClip = {
        CatAnimationClip(
            name: "lieDown",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.LieDown.asset,
                frameCount: CatAnimationConfig.LieDown.frameCount
            ),
            frameDurations: CatAnimationConfig.LieDown.frameDurations
        )
    }()

    /// Sleep cycle — looping rest state.
    static let sleep: CatAnimationClip = {
        CatAnimationClip(
            name: "sleep",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Sleep.asset,
                frameCount: CatAnimationConfig.Sleep.frameCount
            ),
            frameDurations: CatAnimationConfig.Sleep.frameDurations
        )
    }()

    /// Playful strike — one-shot pounce/swat flourish.
    static let attack: CatAnimationClip = {
        CatAnimationClip(
            name: "attack",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Attack.asset,
                frameCount: CatAnimationConfig.Attack.frameCount
            ),
            frameDurations: CatAnimationConfig.Attack.frameDurations
        )
    }()

    /// Startled reaction — one-shot fright/recoil state.
    static let fright: CatAnimationClip = {
        CatAnimationClip(
            name: "fright",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.Fright.asset,
                frameCount: CatAnimationConfig.Fright.frameCount
            ),
            frameDurations: CatAnimationConfig.Fright.frameDurations
        )
    }()

    /// Wall cling — brief hold state when the cat grips a vertical screen edge.
    static let wallGrab: CatAnimationClip = {
        CatAnimationClip(
            name: "wallGrab",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.WallGrab.asset,
                frameCount: CatAnimationConfig.WallGrab.frameCount
            ),
            frameDurations: CatAnimationConfig.WallGrab.frameDurations
        )
    }()

    /// Wall climb — active upward movement along a vertical screen edge.
    static let wallClimb: CatAnimationClip = {
        CatAnimationClip(
            name: "wallClimb",
            frames: CatSpriteLoader.loadStrip(
                asset:CatAnimationConfig.WallClimb.asset,
                frameCount: CatAnimationConfig.WallClimb.frameCount
            ),
            frameDurations: CatAnimationConfig.WallClimb.frameDurations
        )
    }()
}
