import SwiftUI

/// Displays the files of a single mini‑app and provides an export action.
///
/// Each file can be opened to view its contents.  The export button
/// generates a ZIP archive via `MiniAppManager` and presents a share sheet.
struct MiniAppDetailView: View {
    let app: MiniApp
    @EnvironmentObject private var miniAppManager: MiniAppManager

    @State private var isExporting = false
    @State private var exportURL: URL?

    var body: some View {
        List {
            ForEach(app.files) { file in
                NavigationLink(value: file) {
                    Text(file.name)
                }
            }
        }
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        do {
                            exportURL = try await miniAppManager.export(app)
                            isExporting = true
                        } catch {
                            print("Export error: \(error)")
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isExporting) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .navigationDestination(for: MiniFile.self) { file in
            FileDetailView(file: file)
        }
    }
}