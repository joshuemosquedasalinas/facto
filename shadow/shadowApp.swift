//
//  shadowApp.swift
//  shadow
//
//  Created by Joshue Mosqueda on 4/8/26.
//

import SwiftUI

@main
struct shadowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 160, minHeight: 160)
        }
        .defaultSize(width: 160, height: 160)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
