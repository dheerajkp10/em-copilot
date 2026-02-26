import Foundation

// MARK: - API Request / Response types

private struct ClaudeAPIMessage: Codable {
    let role: String
    let content: String
}

private struct ClaudeAPIRequest: Codable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [ClaudeAPIMessage]
}

private struct ClaudeAPIResponse: Codable {
    struct Content: Codable {
        let type: String
        let text: String
    }
    struct APIError: Codable {
        let type: String
        let message: String
    }
    let content: [Content]?
    let error: APIError?
}

// MARK: - ClaudeService

@MainActor
final class ClaudeService: ObservableObject {
    static let shared = ClaudeService()

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-opus-4-6"

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "em_copilot_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "em_copilot_api_key") }
    }

    enum ClaudeError: LocalizedError {
        case missingAPIKey
        case httpError(Int, String)
        case apiError(String)
        case decodingError

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "No API key configured. Go to Settings and add your Anthropic API key."
            case .httpError(let code, let message):
                return "HTTP \(code): \(message)"
            case .apiError(let message):
                return "Claude API error: \(message)"
            case .decodingError:
                return "Failed to parse the API response."
            }
        }
    }

    func generate(systemPrompt: String, userMessage: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ClaudeError.missingAPIKey
        }

        let body = ClaudeAPIRequest(
            model: model,
            max_tokens: 4096,
            system: systemPrompt,
            messages: [ClaudeAPIMessage(role: "user", content: userMessage)]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json",    forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey,                forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",          forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeError.apiError("No HTTP response received.")
        }

        let parsed: ClaudeAPIResponse
        do {
            parsed = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        } catch {
            throw ClaudeError.decodingError
        }

        if http.statusCode != 200 {
            let message = parsed.error?.message ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeError.httpError(http.statusCode, message)
        }

        guard let text = parsed.content?.first?.text else {
            throw ClaudeError.apiError("Empty response from Claude.")
        }

        return text
    }
}
