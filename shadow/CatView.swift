import AppKit
import SwiftUI

/// Renders the current frame from a CatAnimationController.
/// Knows nothing about timing or clip logic — pure display.
struct CatView: View {
    @ObservedObject var controller: CatAnimationController

    var body: some View {
        Group {
            if let frame = controller.currentFrame {
                Image(nsImage: frame)
                    .resizable()
                    .interpolation(.none)
                    .frame(
                        width:  CatAnimationConfig.frameSize.width  * CatAnimationConfig.displayScale,
                        height: CatAnimationConfig.frameSize.height * CatAnimationConfig.displayScale
                    )
            }
        }
    }
}
