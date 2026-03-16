import Foundation

/// Errors returned by GeminiClient.
enum GeminiError: Error, LocalizedError {
    case noKeys
    case invalidResponse
    case decodingFailure
    case httpError(Int)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noKeys:
            return "No API keys configured."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingFailure:
            return "Failed to decode the model's output as JSON."
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .unknown(let err):
            return err.localizedDescription
        }
    }
}

/// A singleton client responsible for communicating with the Gemini API.
class GeminiClient {
    static let shared = GeminiClient()
    private init() {}

    /// Generates a mini‑app by sending a prompt to the Gemini API.
    ///
    /// - Parameters:
    ///   - prompt: The user’s description of the desired app and system instructions.
    ///   - model: The model name to call (for example, `gemini-3.1-flash-lite-preview`).
    ///   - apiKeys: Ordered list of API keys.  The client will try each key until a request succeeds.
    /// - Returns: An array of `MiniFile` objects extracted from the model’s JSON output.
    @MainActor
    func generateFiles(prompt: String, model: String, apiKeys: [String]) async throws -> [MiniFile] {
        guard !apiKeys.isEmpty else { throw GeminiError.noKeys }
        var lastError: Error = GeminiError.noKeys
        for key in apiKeys {
            do {
                let text = try await sendRequest(prompt: prompt, model: model, apiKey: key)
                // Parse the model's text as JSON
                guard let data = text.data(using: .utf8) else { throw GeminiError.decodingFailure }
                let decoder = JSONDecoder()
                let result = try decoder.decode(GeneratedApp.self, from: data)
                // Map to MiniFile
                let files = result.files.map { MiniFile(name: $0.name, content: $0.content) }
                return files
            } catch {
                lastError = error
                // Continue to next key if this error is due to HTTP
                if case GeminiError.httpError(let code) = error {
                    // fallback on 401, 403, 429, 5xx
                    if [401, 403, 429].contains(code) || (500...599).contains(code) {
                        continue
                    }
                }
            }
        }
        throw lastError
    }

    // MARK: - Private helpers

    private struct GeminiAPIResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String?
                }
                let parts: [Part]
            }
            let content: Content
        }
        let candidates: [Candidate]
    }

    /// Sends a raw request to the Gemini API and returns the plain text response.
    private func sendRequest(prompt: String, model: String, apiKey: String) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        guard let url = URL(string: urlString) else { throw GeminiError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        // Compose the request body.  The model expects a list of contents with parts
        // containing plain text.  We send only one message containing the user prompt.
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw GeminiError.invalidResponse }
        let status = httpResponse.statusCode
        guard (200...299).contains(status) else { throw GeminiError.httpError(status) }
        // Decode the response structure
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(GeminiAPIResponse.self, from: data)
        guard let text = apiResponse.candidates.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }
        return text
    }
}

/// Represents the JSON object returned by the model.  The model should
/// return something like: { "files": [ { "name": "App.swift", "content": "..." }, ... ] }
struct GeneratedApp: Decodable {
    struct GeneratedFile: Decodable {
        let name: String
        let content: String
    }
    let files: [GeneratedFile]
}