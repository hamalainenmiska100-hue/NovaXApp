import Foundation
import Combine

/// Configuration for the NovaX host app.
///
/// Stores the currently selected model name.  Defaults to a cost‑sensitive
/// fast model (`gemini‑3.1‑flash‑lite‑preview`) which is well suited for high
/// volume requests【15730787711370†L548-L578】.
class AppConfig: ObservableObject {
    @Published var model: String {
        didSet {
            UserDefaults.standard.set(model, forKey: "selectedModel")
        }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedModel") {
            self.model = saved
        } else {
            self.model = "gemini-3.1-flash-lite-preview"
        }
    }
}