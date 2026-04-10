import AppKit
import Combine
import SwiftUI

/// Top-level controller that owns observable state and the behavior task lifecycle.
/// All behavior routing is delegated to BehaviorDispatcher; behavior logic lives in the behavior modules.
@MainActor
final class CatBehaviorController: ObservableObject, CatBehaviorContext {

    // MARK: - Observable state

    @Published private(set) var currentFrame: NSImage?
    @Published private(set) var facingRight: Bool = true
    @Published private(set) var verticalOffset: CGFloat = 0

    // MARK: - Internal state

    private(set) var state: CatState = .idle
    var lastMouseReactionAt: Date = .distantPast

    private var _motionProxy: WindowMotionProxy?
    private var behaviorTask: Task<Void, Never>?

    lazy var player: AnimationPlayer = { AnimationPlayer(context: self) }()

    // MARK: - CatBehaviorContext

    var motionProxy: WindowMotionProxy {
        _motionProxy ?? WindowMotionProxy() // Should always be set before the loop starts
    }

    var currentFacingRight: Bool { facingRight }
    var currentState: CatState { state }

    func updateFrame(_ image: NSImage?)          { currentFrame = image }
    func updateFacingRight(_ facing: Bool)       { facingRight = facing }
    func updateVerticalOffset(_ offset: CGFloat) { verticalOffset = offset }
    func updateState(_ newState: CatState)       { state = newState }

    func settleToIdle() {
        state = .idle
        verticalOffset = 0
        currentFrame = CatAnimationClip.idle.frames.first
    }

    func settleToIdleFacing(_ goRight: Bool) {
        state = .idle
        facingRight = goRight
        verticalOffset = 0
        currentFrame = CatAnimationClip.idle.frames.first
    }

    // MARK: - Lifecycle

    deinit { behaviorTask?.cancel() }

    func start(motionProxy: WindowMotionProxy) {
        self._motionProxy = motionProxy
        behaviorTask?.cancel()
        behaviorTask = Task { [weak self] in
            await self?.runBehaviorLoop()
        }
    }

    // MARK: - Main loop

    private func runBehaviorLoop() async {
        settleToIdle()
        while !Task.isCancelled {
            await RestBehaviors.runIdlePhase(context: self)
            guard !Task.isCancelled else { return }
            await BehaviorDispatcher.selectNextBehavior(context: self)
        }
    }

    // MARK: - Mouse reaction (CatBehaviorContext requirement)

    func reactToNearbyMouseIfNeeded() async -> Bool {
        guard state == .idle || state == .sit || state == .lieDown || state == .sleep else { return false }
        guard Date().timeIntervalSince(lastMouseReactionAt) >= CatAnimationConfig.Mouse.reactionCooldown else { return false }
        guard motionProxy.isCursorNearWindow(maxDistance: CatAnimationConfig.Mouse.noticeDistance) else { return false }
        guard Double.random(in: 0..<1) < CatAnimationConfig.Mouse.reactionChance else { return false }

        lastMouseReactionAt = Date()
        facingRight = motionProxy.cursorIsToRightOfWindowCenter()

        if motionProxy.isCursorVeryCloseToWindow(padding: CatAnimationConfig.Mouse.pouncePadding) {
            await BehaviorDispatcher.handle(.attack, context: self)
            return true
        }
        return false
    }
}
