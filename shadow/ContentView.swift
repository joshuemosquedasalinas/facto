//
//  ContentView.swift
//  shadow
//
//  Created by Joshue Mosqueda on 4/8/26.
//

import SwiftUI

// MARK: - SpeechBubbleView

private struct SpeechBubbleView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.black, lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
            )
    }
}

// MARK: - ContentView

struct ContentView: View {
    // Change this to set the cat's display name.
    private let catName = "Shadow"

    @State private var isHovering = true
    @State private var isNameVisible = false
    @StateObject private var motionProxy        = WindowMotionProxy()
    @StateObject private var behaviorController = CatBehaviorController()

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            CatView(controller: behaviorController)
                .contextMenu {
                    Button(action: { isHovering.toggle() }) {
                        HStack {
                            Text("Hover")
                            if isHovering { Image(systemName: "checkmark") }
                        }
                    }
                    Divider()
                    ForEach(CatVariant.allCases, id: \.self) { variant in
                        Button(action: { behaviorController.switchVariant(variant) }) {
                            HStack {
                                Text(variant.displayName)
                                if behaviorController.currentVariant == variant {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            // Speech bubble — appears beside the cat on the side it is facing.
            if let text = behaviorController.meowText {
                VStack {
                    Spacer(minLength: 0)
                    HStack {
                        if behaviorController.facingRight {
                            Spacer(minLength: 0)
                            SpeechBubbleView(text: text)
                        } else {
                            SpeechBubbleView(text: text)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.horizontal, 8)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -10)
                .transition(.move(edge: behaviorController.facingRight ? .trailing : .leading).combined(with: .opacity))
            }
            // Name label overlaid in the transparent zone at the top of the sprite,
            // just above the cat's head. Adjust nameBarHeight to nudge up or down.
            VStack {
                Text(catName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(.top, CatAnimationConfig.Render.nameBarHeight)
                    .opacity(isNameVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isNameVisible)
                Spacer()
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: behaviorController.meowText)
        .onHover { isNameVisible = $0 }
        .background(WindowAccessor(isHovering: isHovering, motionProxy: motionProxy))
        .onAppear {
            behaviorController.start(motionProxy: motionProxy)
        }
    }
}
