import Foundation
import Combine

/// Manages a list of Gemini API keys.
///
/// Keys are persisted in UserDefaults under the `apiKeys` key.  A maximum of
/// five keys can be stored.  The `keys` array preserves order; the first
/// element is used first when making a request.  If a request fails (401,
/// 403, 429 or a 5xx error), the client should attempt the next key.
class APIKeyManager: ObservableObject {
    @Published var keys: [String] {
        didSet { saveKeys() }
    }

    init() {
        // Load keys from UserDefaults.  In a production app you should
        // encrypt and store these in the Keychain.
        if let saved = UserDefaults.standard.array(forKey: "apiKeys") as? [String] {
            self.keys = saved
        } else {
            self.keys = []
        }
    }

    /// Adds a new key if there’s room (max 5).
    func addKey(_ key: String) {
        guard !key.isEmpty else { return }
        // Prevent duplicates
        if keys.contains(key) { return }
        if keys.count < 5 {
            keys.append(key)
        }
    }

    /// Removes a key at a given index.
    func removeKey(at offsets: IndexSet) {
        keys.remove(atOffsets: offsets)
    }

    /// Moves keys during a reorder.
    func moveKeys(from source: IndexSet, to destination: Int) {
        keys.move(fromOffsets: source, toOffset: destination)
    }

    /// Persists keys to UserDefaults.
    private func saveKeys() {
        UserDefaults.standard.set(keys, forKey: "apiKeys")
    }
}