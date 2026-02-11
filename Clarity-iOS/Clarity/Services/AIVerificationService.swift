import Foundation

/// Photo-based challenge verification using Google Gemini API.
/// Used for the highest friction levels where users must prove a real-world action.
class AIVerificationService {
    static let shared = AIVerificationService()

    private init() {}

    enum VerificationType: String {
        case outside
        case water
        case standing
    }

    struct VerificationResult {
        let verified: Bool
        let message: String
    }

    /// Whether the Gemini API key is configured and verification is available.
    func isAvailable() -> Bool {
        apiKey != nil
    }

    /// Verify a photo challenge against the expected type using Gemini vision.
    func verifyChallenge(imageData: Data, type: VerificationType) async -> VerificationResult {
        guard let key = apiKey else {
            return VerificationResult(
                verified: true,
                message: "Challenge accepted (verification unavailable)"
            )
        }

        let prompt = buildPrompt(for: type)
        let base64Image = imageData.base64EncodedString()

        // Build Gemini API request
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(key)"
        guard let url = URL(string: urlString) else {
            return fallbackResult
        }

        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    [
                        "inline_data": [
                            "mime_type": "image/jpeg",
                            "data": base64Image,
                        ]
                    ],
                ]
            ]]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return fallbackResult
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                return fallbackResult
            }

            return parseResponse(data)
        } catch {
            return fallbackResult
        }
    }

    // MARK: - Private

    private var apiKey: String? {
        // Try Info.plist first, then environment
        if let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
           !key.isEmpty
        {
            return key
        }
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !key.isEmpty
        {
            return key
        }
        return nil
    }

    private var fallbackResult: VerificationResult {
        VerificationResult(verified: true, message: "Challenge accepted (verification unavailable)")
    }

    private func buildPrompt(for type: VerificationType) -> String {
        let action: String
        switch type {
        case .outside:
            action = "outside (outdoors, not inside a building)"
        case .water:
            action = "holding or drinking a glass/bottle of water"
        case .standing:
            action = "standing up (not sitting or lying down)"
        }
        return """
            Does this photo show the person is \(action)? \
            Respond ONLY with JSON: {"verified": true/false, "message": "brief explanation"}
            """
    }

    private func parseResponse(_ data: Data) -> VerificationResult {
        // Gemini response structure: candidates[0].content.parts[0].text
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else {
            return fallbackResult
        }

        // Extract JSON from the response text (may be wrapped in markdown code fences)
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let resultData = cleaned.data(using: .utf8),
              let resultJSON = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any],
              let verified = resultJSON["verified"] as? Bool,
              let message = resultJSON["message"] as? String
        else {
            return fallbackResult
        }

        return VerificationResult(verified: verified, message: message)
    }
}
