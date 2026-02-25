import Foundation

/// Simple Claude API integration for the Thought Untangler feature.
/// Stores API key in UserDefaults, rate-limited to 10 calls per day.
@Observable
@MainActor
final class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let defaults = UserDefaults.standard
    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    var isLoading = false
    var dailyUsageCount: Int = 0
    private let maxDailyUsage = 10

    var apiKey: String {
        get { defaults.string(forKey: "claude.apiKey") ?? "" }
        set { defaults.set(newValue, forKey: "claude.apiKey") }
    }

    var hasAPIKey: Bool { !apiKey.isEmpty }
    var canMakeRequest: Bool { dailyUsageCount < maxDailyUsage && hasAPIKey }
    var remainingCalls: Int { Swift.max(0, maxDailyUsage - dailyUsageCount) }

    private init() {
        loadDailyUsage()
    }

    // MARK: - Send Thought Dump

    /// Sends a thought dump to Claude and returns structured reflection.
    func untangleThought(_ text: String) async throws -> String {
        guard canMakeRequest else {
            throw ClaudeError.rateLimited
        }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ClaudeError.emptyInput
        }

        isLoading = true
        defer { isLoading = false }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-5-20250929",
            "max_tokens": 1024,
            "system": """
                You are a compassionate thinking partner. The user is dumping their thoughts \
                to externalize and organize them. Help them see patterns, identify what matters, \
                and find clarity. Be warm, brief, and structured. Use sections: \
                What I'm Hearing, Patterns, What Might Help.
                """,
            "messages": [
                ["role": "user", "content": text]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw ClaudeError.apiError(statusCode: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let responseText = firstBlock["text"] as? String else {
            throw ClaudeError.invalidResponse
        }

        // Track usage
        incrementDailyUsage()

        return responseText
    }

    // MARK: - Rate Limiting

    func resetDaily() {
        let today = formattedToday()
        let lastReset = defaults.string(forKey: "claude.lastResetDate") ?? ""
        if lastReset != today {
            dailyUsageCount = 0
            defaults.set(0, forKey: "claude.dailyUsage")
            defaults.set(today, forKey: "claude.lastResetDate")
        }
    }

    private func loadDailyUsage() {
        let today = formattedToday()
        let lastReset = defaults.string(forKey: "claude.lastResetDate") ?? ""
        if lastReset == today {
            dailyUsageCount = defaults.integer(forKey: "claude.dailyUsage")
        } else {
            resetDaily()
        }
    }

    private func incrementDailyUsage() {
        dailyUsageCount += 1
        defaults.set(dailyUsageCount, forKey: "claude.dailyUsage")
    }

    private func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Errors

enum ClaudeError: LocalizedError {
    case rateLimited
    case emptyInput
    case networkError
    case apiError(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "Daily limit reached. Try again tomorrow."
        case .emptyInput:
            return "Please write something first."
        case .networkError:
            return "Network error. Check your connection."
        case .apiError(let code):
            return "API error (status \(code)). Check your API key."
        case .invalidResponse:
            return "Unexpected response format."
        }
    }
}
