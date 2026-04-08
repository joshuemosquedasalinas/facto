import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}

actor OpenRouterClient {
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    func fetchFact(prompt: String) async throws -> String {
        try await completeChat(
            prompt: prompt,
            history: [],
            userMessage: "Share exactly one concise, interesting fact. Keep it under 80 words."
        )
    }

    func sendConversation(prompt: String, history: [ChatMessage], userMessage: String) async throws -> String {
        try await completeChat(prompt: prompt, history: history, userMessage: userMessage)
    }

    private func completeChat(prompt: String, history: [ChatMessage], userMessage: String) async throws -> String {
        guard let apiKey = EnvLoader.value(forKey: "OPENROUTER_API_KEY"), !apiKey.isEmpty else {
            throw OpenRouterError.missingAPIKey
        }

        let model = EnvLoader.value(forKey: "OPENROUTER_MODEL") ?? "perplexity/sonar"
        let body = OpenRouterRequest(
            model: model,
            messages: [ChatMessage(role: "system", content: prompt)] + history + [ChatMessage(role: "user", content: userMessage)]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("shadow", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw OpenRouterError.serverError(message)
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else {
            throw OpenRouterError.emptyResponse
        }

        return content
    }
}

private struct OpenRouterRequest: Codable {
    let model: String
    let messages: [ChatMessage]
}

private struct OpenRouterResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

enum OpenRouterError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case emptyResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing `OPENROUTER_API_KEY`."
        case .invalidResponse:
            return "The response from OpenRouter was invalid."
        case .emptyResponse:
            return "OpenRouter returned an empty response."
        case .serverError(let message):
            return message
        }
    }
}
