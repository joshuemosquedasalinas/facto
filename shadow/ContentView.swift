//
//  ContentView.swift
//  shadow
//
//  Created by Joshue Mosqueda on 4/8/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            Color.clear
            AnimatedCatView(resourceName: "Waiting", frameCount: 6, frameSize: CGSize(width: 32, height: 32), scale: 4)
                .contextMenu {
                    Button(action: {
                        isHovering.toggle()
                    }) {
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
