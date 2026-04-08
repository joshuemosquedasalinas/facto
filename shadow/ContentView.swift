//
//  ContentView.swift
//  shadow
//
//  Created by Joshue Mosqueda on 4/8/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isHovering = false
    @StateObject private var controller = CatAnimationController(clip: .idleBlink)

    var body: some View {
        ZStack {
            Color.clear
            CatView(controller: controller)
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
        .padding(18)
        .background(WindowAccessor(isHovering: isHovering))
    }
}
