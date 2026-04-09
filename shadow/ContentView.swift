//
//  ContentView.swift
//  shadow
//
//  Created by Joshue Mosqueda on 4/8/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isHovering = false
    @StateObject private var motionProxy       = WindowMotionProxy()
    @StateObject private var behaviorController = CatBehaviorController()

    var body: some View {
        ZStack {
            Color.clear
            CatView(controller: behaviorController)
                .contextMenu {
                    Button(action: { isHovering.toggle() }) {
                        HStack {
                            Text("Hover")
                            if isHovering {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
        }
        .background(WindowAccessor(isHovering: isHovering, motionProxy: motionProxy))
        .onAppear {
            behaviorController.start(motionProxy: motionProxy)
        }
    }
}
