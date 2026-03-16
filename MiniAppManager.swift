import Foundation
import SwiftUI
import Darwin

/// Manages persistence and operations on mini‑apps.
@MainActor
class MiniAppManager: ObservableObject {
    @Published private(set) var apps: [MiniApp] = []

    init() {
        Task { await loadApps() }
    }

    /// Loads mini‑apps from the Documents directory.  Each folder under
    /// `miniapps` represents one app and contains an `info.json` file and
    /// multiple source files.
    func loadApps() async {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let root = docs.appendingPathComponent("miniapps")
        do {
            if !fm.fileExists(atPath: root.path) {
                try fm.createDirectory(at: root, withIntermediateDirectories: true)
            }
            let contents = try fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            var loaded: [MiniApp] = []
            for folder in contents where folder.hasDirectoryPath {
                let infoURL = folder.appendingPathComponent("info.json")
                guard let infoData = try? Data(contentsOf: infoURL) else { continue }
                let decoder = JSONDecoder()
                if let app = try? decoder.decode(MiniApp.self, from: infoData) {
                    // Load file contents
                    let fileURLs = try fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).filter { $0.pathExtension == "swift" }
                    var files: [MiniFile] = []
                    for fileURL in fileURLs {
                        if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                            let name = fileURL.lastPathComponent
                            files.append(MiniFile(name: name, content: content))
                        }
                    }
                    var loadedApp = app
                    loadedApp.files = files
                    loaded.append(loadedApp)
                }
            }
            // Sort by creation date descending
            self.apps = loaded.sorted { $0.created > $1.created }
        } catch {
            print("Error loading apps: \(error)")
        }
    }

    /// Persists a new mini‑app to disk and updates the in‑memory list.
    func createMiniApp(name: String, files: [MiniFile]) async {
        let app = MiniApp(id: UUID(), name: name, created: Date(), files: files)
        do {
            let folderURL = try app.folderURL()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            // Save each file
            for file in files {
                let fileURL = folderURL.appendingPathComponent(file.name)
                try file.content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            // Save info.json
            let infoURL = folderURL.appendingPathComponent("info.json")
            let data = try JSONEncoder().encode(app)
            try data.write(to: infoURL)
            // Update list
            apps.insert(app, at: 0)
        } catch {
            print("Failed to create mini app: \(error)")
        }
    }

    /// Deletes a mini‑app from disk and removes it from the list.
    func delete(_ app: MiniApp) async {
        do {
            let url = try app.folderURL()
            try FileManager.default.removeItem(at: url)
            apps.removeAll { $0.id == app.id }
        } catch {
            print("Error deleting mini app: \(error)")
        }
    }

    /// Duplicates a mini‑app by copying its files into a new folder and inserting
    /// the duplicate into the list.
    func duplicate(_ app: MiniApp) async {
        do {
            // Create new ID
            var duplicateApp = app
            duplicateApp.id = UUID()
            duplicateApp.name += " Copy"
            duplicateApp.created = Date()
            // Save
            let folderURL = try duplicateApp.folderURL()
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            for file in duplicateApp.files {
                let fileURL = folderURL.appendingPathComponent(file.name)
                try file.content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            let infoURL = folderURL.appendingPathComponent("info.json")
            let data = try JSONEncoder().encode(duplicateApp)
            try data.write(to: infoURL)
            apps.insert(duplicateApp, at: 0)
        } catch {
            print("Error duplicating mini app: \(error)")
        }
    }

    /// Exports a mini‑app’s folder to a zip archive and returns the URL of the zip file.
    /// Exports a mini-app’s folder to a zip archive and returns the URL of the zip file.
func export(_ app: MiniApp) async throws -> URL {
    let fm = FileManager.default
    let folderURL = try app.folderURL()
    let tempDir = fm.temporaryDirectory

    let zipURL = tempDir.appendingPathComponent(
        "\(app.name.replacingOccurrences(of: " ", with: "_"))_\(app.id).zip"
    )

    if fm.fileExists(atPath: zipURL.path) {
        try fm.removeItem(at: zipURL)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    process.arguments = ["-r", zipURL.path, "."]

    process.currentDirectoryURL = folderURL

    try process.run()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
        throw NSError(domain: "ZipError", code: 1)
    }

    return zipURL
}
}
