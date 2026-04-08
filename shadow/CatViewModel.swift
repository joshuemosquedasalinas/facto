import AppKit
import Combine
import Foundation

@MainActor
final class CatViewModel: ObservableObject {
    @Published var bubbleText: String?
    @Published var composerText = ""
    @Published var composerPlaceholder = "Reply to the cat..."
    @Published var isComposerVisible = false
    @Published var isLoading = false
    @Published var isPromptEditorPresented = false
    @Published var promptDraft = ""

    private let defaultPrompt = "You are Sheldon from The Big Bang Theory. Tell me a fact about science, mathematics, history, or engineering."
    private let promptKey = "factPrompt"
    private let bubbleLifetime: Duration = .seconds(120)
    private let factInterval: TimeInterval = 1800

    private let client = OpenRouterClient()
    private var factTimer: Timer?
    private var bubbleDismissTask: Task<Void, Never>?
    private var conversationHistory: [ChatMessage] = []
    private var bubbleIsConversationSeed = false

    init() {
        promptDraft = storedPrompt
        startFactTimer()
    }

    deinit {
        factTimer?.invalidate()
        bubbleDismissTask?.cancel()
    }

    var trimmedComposerText: String {
        composerText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSaveCurrentBubble: Bool {
        guard let bubbleText else { return false }
        return !bubbleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var storedPrompt: String {
        let savedPrompt = UserDefaults.standard.string(forKey: promptKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return savedPrompt?.isEmpty == false ? savedPrompt! : defaultPrompt
    }

    func beginConversation() {
        composerPlaceholder = "Say something to the cat..."
        isComposerVisible = true

        if bubbleText == nil {
            bubbleText = "What do you want to talk about?"
            bubbleIsConversationSeed = false
            keepBubbleVisible()
        }
    }

    func prepareReply() {
        composerPlaceholder = "Reply to the cat..."
        isComposerVisible = true
        keepBubbleVisible()
    }

    func submitComposer() {
        let message = trimmedComposerText
        guard !message.isEmpty, !isLoading else { return }

        if conversationHistory.isEmpty, let bubbleText, bubbleIsConversationSeed {
            conversationHistory.append(ChatMessage(role: "assistant", content: bubbleText))
        }

        composerText = ""
        isComposerVisible = false
        keepBubbleVisible()

        Task {
            await sendConversationMessage(message)
        }
    }

    func requestFactNow() {
        Task {
            await fetchFact()
        }
    }

    func saveCurrentBubble() {
        guard let bubbleText, !bubbleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let formatter = ISO8601DateFormatter()
        let entry = "[\(formatter.string(from: Date()))]\n\(bubbleText)\n\n"

        do {
            let fileURL = try savedFactsURL()
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                if let data = entry.data(using: .utf8) {
                    try handle.write(contentsOf: data)
                }
            } else {
                try entry.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            present(text: "I couldn't save that fact locally: \(error.localizedDescription)", seedsConversation: false)
        }
    }

    func openSavedFacts() {
        do {
            let fileURL = try savedFactsURL()
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                try "".write(to: fileURL, atomically: true, encoding: .utf8)
            }
            NSWorkspace.shared.open(fileURL)
        } catch {
            present(text: "I couldn't open the saved facts file: \(error.localizedDescription)", seedsConversation: false)
        }
    }

    func beginPromptEditing() {
        promptDraft = storedPrompt
        isPromptEditorPresented = true
    }

    func savePromptEdits() {
        let updatedPrompt = promptDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalPrompt = updatedPrompt.isEmpty ? defaultPrompt : updatedPrompt
        UserDefaults.standard.set(finalPrompt, forKey: promptKey)
        promptDraft = finalPrompt
    }

    private func startFactTimer() {
        factTimer?.invalidate()
        factTimer = Timer.scheduledTimer(withTimeInterval: factInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchFact()
            }
        }

        if let factTimer {
            RunLoop.main.add(factTimer, forMode: .common)
        }
    }

    private func fetchFact() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let fact = try await client.fetchFact(prompt: storedPrompt)
            conversationHistory = [ChatMessage(role: "assistant", content: fact)]
            present(text: fact, seedsConversation: true)
        } catch {
            present(text: "I couldn't reach OpenRouter. Check `.env` for `OPENROUTER_API_KEY` and try again.\n\n\(error.localizedDescription)", seedsConversation: false)
        }

        isLoading = false
    }

    private func sendConversationMessage(_ message: String) async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let reply = try await client.sendConversation(prompt: storedPrompt, history: conversationHistory, userMessage: message)
            conversationHistory.append(ChatMessage(role: "user", content: message))
            conversationHistory.append(ChatMessage(role: "assistant", content: reply))
            present(text: reply, seedsConversation: true)
        } catch {
            present(text: "I couldn't send that message.\n\n\(error.localizedDescription)", seedsConversation: false)
        }

        isLoading = false
    }

    private func present(text: String, seedsConversation: Bool) {
        bubbleText = text
        bubbleIsConversationSeed = seedsConversation
        keepBubbleVisible()
    }

    private func keepBubbleVisible() {
        bubbleDismissTask?.cancel()
        bubbleDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: bubbleLifetime)
            guard !Task.isCancelled else { return }
            self?.bubbleText = nil
            self?.isComposerVisible = false
        }
    }

    private func savedFactsURL() throws -> URL {
        let appSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = appSupport.appendingPathComponent("shadow", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("saved_facts.txt")
    }
}
