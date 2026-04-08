//
//  ContentView.swift
//  shadow
//
//  Created by Joshue Mosqueda on 4/8/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.clear
            AnimatedCatView(resourceName: "Waiting", frameCount: 6, frameSize: CGSize(width: 32, height: 32), scale: 4)
        }
        .padding(18)
        .background(WindowAccessor())
    }
}
