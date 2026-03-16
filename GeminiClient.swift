import Foundation

struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String?
            }
            let parts: [Part]
        }
        let content: Content
    }

    let candidates: [Candidate]
}

class GeminiClient {

    static let shared = GeminiClient()

    func generateFiles(prompt: String, model: String, apiKeys: [String]) async throws -> [MiniFile] {

        for key in apiKeys {

            do {
                return try await attempt(prompt: prompt, model: model, apiKey: key)
            } catch {
                continue
            }

        }

        throw NSError(domain: "GeminiError", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "All API keys failed"
        ])
    }

    private func attempt(prompt: String, model: String, apiKey: String) async throws -> [MiniFile] {

        let url = URL(string:
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = decoded.candidates.first?.content.parts.first?.text else {
            throw NSError(domain: "GeminiError", code: 2)
        }

        // For now just generate one file
        let file = MiniFile(
            name: "GeneratedView.swift",
            content: text
        )

        return [file]
    }
}
