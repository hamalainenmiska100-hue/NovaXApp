import SwiftUI

/// A view for creating a new mini‑app using the Gemini API.
///
/// Users provide a name, prompt and choose a model.  They can also
/// manage up to five API keys directly within the form.  When the
/// “Generate” button is tapped the view calls `GeminiClient` and shows
/// a progress indicator.  Any errors are displayed below the form.
struct NewMiniAppView: View {
    @EnvironmentObject private var apiKeyManager: APIKeyManager
    @EnvironmentObject private var config: AppConfig
    @EnvironmentObject private var miniAppManager: MiniAppManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var prompt: String = ""
    @State private var newKey: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Mini‑App")) {
                    TextField("Name", text: $name)
                    TextEditor(text: $prompt)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.25))
                        )
                }

                Section(header: Text("Model")) {
                    TextField("Model identifier", text: $config.model)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Text("Examples: gemini‑3.1‑flash‑lite‑preview, gemini‑2.5‑pro, gemini‑3‑flash‑preview")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("API Keys"), footer: Text("You can add up to five keys.  The first key will be used first; the app falls back to the next key if a request fails.")) {
                    ForEach(apiKeyManager.keys.indices, id: \.__self) { index in
                        HStack {
                            Text("Key \(index + 1)")
                            Spacer()
                            let key = apiKeyManager.keys[index]
                            // Show last 4 characters only for a bit of privacy
                            Text("••••\(key.suffix(4))")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        apiKeyManager.removeKey(at: indexSet)
                    }
                    if apiKeyManager.keys.count < 5 {
                        HStack {
                            TextField("New API key", text: $newKey)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                            Button("Add") {
                                let trimmed = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty {
                                    apiKeyManager.addKey(trimmed)
                                }
                                newKey = ""
                            }
                            .disabled(newKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }

                Section {
                    if isGenerating {
                        HStack {
                            ProgressView()
                            Text("Generating…")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Button(action: {
                            Task { await generateApp() }
                        }) {
                            HStack {
                                Spacer()
                                Text("Generate")
                                Spacer()
                            }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || apiKeyManager.keys.isEmpty)
                    }
                }

                if let message = errorMessage {
                    Section {
                        Text(message)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Mini‑App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    /// Initiates a call to the Gemini API to generate a new mini‑app.  On
    /// success the mini‑app is saved via `MiniAppManager` and the view
    /// dismisses itself.  On failure an error message is presented.
    private func generateApp() async {
        isGenerating = true
        defer { isGenerating = false }
        errorMessage = nil
        do {
            let files = try await GeminiClient.shared.generateFiles(prompt: prompt, model: config.model, apiKeys: apiKeyManager.keys)
            await miniAppManager.createMiniApp(name: name, files: files)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}