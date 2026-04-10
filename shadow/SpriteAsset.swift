/// Compile-time registry of every sprite strip PNG bundled with the app.
///
/// Using an enum instead of raw strings means a renamed or missing asset is
/// caught at compile time rather than silently producing an empty clip at runtime.
enum SpriteAsset: String {
    case idle         = "cat05_idle_strip8"
    case idleBlink    = "cat05_idle_blink_strip8"
    case walk         = "cat05_walk_strip8"
    case sneak        = "cat05_sneak_strip8"
    case run          = "cat05_run_strip4"
    case dash         = "cat05_dash_strip9"
    case crouch       = "cat05_crouch_strip8"
    case sit          = "cat05_sit_strip8"
    case lieDown      = "cat05_liedown_strip24"
    case sleep        = "cat05_sleep_strip8"
    case attack       = "cat05_attack_strip7"
    case fright       = "cat05_fright_strip8"
    case jump         = "cat05_jump_strip4"
    case fall         = "cat05_fall_strip3"
    case land         = "cat05_land_strip2"
    case wallGrab     = "cat05_wallgrab_strip8"
    case wallClimb    = "cat05_wallclimb_strip8"
}
