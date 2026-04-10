import AppKit
import SwiftUI

/// Renders the current frame from a CatBehaviorController.
/// Applies a horizontal flip when the cat faces left.
struct CatView: View {
    @ObservedObject var controller: CatBehaviorController

    var body: some View {
        Group {
            if let frame = controller.currentFrame {
                Image(nsImage: frame)
                    .resizable()
                    .interpolation(.none)
                    .frame(
                        width:  CatAnimationConfig.Render.frameSize.width  * CatAnimationConfig.Render.displayScale,
                        height: CatAnimationConfig.Render.frameSize.height * CatAnimationConfig.Render.displayScale
                    )
                    .scaleEffect(x: controller.facingRight ? 1 : -1, y: 1)
                    .offset(y: controller.verticalOffset)
            }
        }
    }
}
