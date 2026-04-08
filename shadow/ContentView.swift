//
//  ContentView.swift
//  shadow
//
//  Created by Joshue Mosqueda on 4/8/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: CatViewModel

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 14) {
                if let bubbleText = model.bubbleText, !bubbleText.isEmpty {
                    SpeechBubbleView(text: bubbleText, isLoading: model.isLoading)
                        .frame(width: 290)
                        .onTapGesture {
                            model.prepareReply()
                        }
                }

                if model.isComposerVisible {
                    HStack(spacing: 8) {
                        TextField(model.composerPlaceholder, text: $model.composerText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...4)
                            .onSubmit {
                                model.submitComposer()
                            }

                        Button("Send") {
                            model.submitComposer()
                        }
                        .keyboardShortcut(.return, modifiers: [])
                        .disabled(model.trimmedComposerText.isEmpty || model.isLoading)
                    }
                    .padding(10)
                    .frame(width: 290)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                AnimatedCatView(resourceName: "Waiting", frameCount: 6, frameSize: CGSize(width: 32, height: 32), scale: 4)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        model.beginConversation()
                    }
                    .contextMenu {
                        Button("Save") {
                            model.saveCurrentBubble()
                        }
                        .disabled(!model.canSaveCurrentBubble)

                        Button("Saved Facts") {
                            model.openSavedFacts()
                        }

                        Button("Edit Fact Prompt") {
                            model.beginPromptEditing()
                        }

                        Divider()

                        Button("Tell Me a Fact Now") {
                            model.requestFactNow()
                        }
                        .disabled(model.isLoading)
                    }
            }
            .padding(18)
        }
        .background(WindowAccessor())
        .sheet(isPresented: $model.isPromptEditorPresented) {
            PromptEditorSheet(promptDraft: $model.promptDraft) {
                model.savePromptEdits()
            }
        }
    }
}

private struct SpeechBubbleView: View {
    let text: String
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            Text(isLoading ? "Thinking..." : "Click bubble to reply")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            SpeechBubbleShape()
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 8)
        )
        .overlay(
            SpeechBubbleShape()
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct PromptEditorSheet: View {
    @Binding var promptDraft: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Fact Prompt")
                .font(.title3.weight(.semibold))

            TextEditor(text: $promptDraft)
                .font(.system(size: 14, design: .monospaced))
                .frame(minHeight: 180)
                .padding(8)
                .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Button("Save Prompt") {
                    onSave()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 280)
    }
}

private struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let tailWidth: CGFloat = 24
        let tailHeight: CGFloat = 16
        let bubbleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailHeight)
        let rounded = RoundedRectangle(cornerRadius: 20, style: .continuous)
        var path = rounded.path(in: bubbleRect)

        let tailCenter = rect.midX - 20
        path.move(to: CGPoint(x: tailCenter - tailWidth / 2, y: bubbleRect.maxY - 2))
        path.addLine(to: CGPoint(x: tailCenter, y: rect.maxY))
        path.addLine(to: CGPoint(x: tailCenter + tailWidth / 2, y: bubbleRect.maxY - 2))
        path.closeSubpath()
        return path
    }
}
