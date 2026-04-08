/// All possible behavior states for the cat.
/// Add new states here as the pet gains behaviors (sit, sleep, lieDown, etc.).
enum CatState: Equatable {
    case idle
    case walkLeft
    case walkRight
}
