/// All possible behavior states for the cat.
/// Add new states here as the pet gains behaviors (sit, sleep, lieDown, etc.).
enum CatState: Equatable {
    case idle
    case crouch
    case jumpLeft
    case jumpRight
    case fallLeft
    case fallRight
    case landLeft
    case landRight
    case sneakLeft
    case sneakRight
    case walkLeft
    case walkRight
    case runLeft
    case runRight
    case dashLeft
    case dashRight
    case sit
    case lieDown
    case sleep
    case wallGrabLeft
    case wallGrabRight
    case wallClimbLeft
    case wallClimbRight
    case attack
    case fright
}
