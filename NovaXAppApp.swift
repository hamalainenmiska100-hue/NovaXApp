import SwiftUI

/// The entry point of the NovaX host application.
///
/// This struct wires up the environment objects used throughout the UI and
/// provides a navigation container.  The app listens for deep link URLs
/// beginning with the `novax://` scheme and attempts to open the specified
/// mini‑app.
@main
struct NovaXAppApp: App {
    @StateObject private var miniAppManager = MiniAppManager()
    @StateObject private var apiKeyManager = APIKeyManager()
    @StateObject private var config = AppConfig()
    // Used for handling deep links to a specific mini‑app.  When non‑nil
    // the root view will navigate to the given app.
    @State private var deepLinkTarget: MiniApp?

    var body: some Scene {
        WindowGroup {
            ContentView(deepLinkTarget: $deepLinkTarget)
                .environmentObject(miniAppManager)
                .environmentObject(apiKeyManager)
                .environmentObject(config)
                .onOpenURL { url in
                    handle(url: url)
                }
        }
    }

    /// Parses incoming URLs and selects the appropriate mini‑app if a
    /// matching identifier is found.  Supported URL format:
    /// `novax://launch/<uuid>`
    private func handle(url: URL) {
        guard url.scheme?.lowercased() == "novax" else { return }
        let pathComponents = url.pathComponents
        // Expected path components: ["/", "launch", "<uuid>"]
        if pathComponents.count >= 3 && pathComponents[1] == "launch" {
            let idString = pathComponents[2]
            if let uuid = UUID(uuidString: idString) {
                if let app = miniAppManager.apps.first(where: { $0.id == uuid }) {
                    deepLinkTarget = app
                }
            }
        }
    }
}