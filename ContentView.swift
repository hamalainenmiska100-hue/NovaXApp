import SwiftUI

/// The main screen of the NovaX app displaying a list of generated mini-apps.
///
/// Users can create a new mini-app, open existing ones, or perform actions via
/// a context menu. When launched via a deep link the `deepLinkTarget` is
/// updated and the view will navigate directly to that mini-app.
struct ContentView: View {
    @EnvironmentObject var miniAppManager: MiniAppManager
    @Binding var deepLinkTarget: MiniApp?

    @State private var navigationPath = NavigationPath()
    @State private var isPresentingNew = false
    @State private var isExporting = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack(path: $navigationPath) {

            List {
                ForEach(miniAppManager.apps) { app in
                    Button {
                        navigationPath.append(app)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "app.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 24))

                            VStack(alignment: .leading) {
                                Text(app.name)
                                    .font(.headline)

                                Text(app.created, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .contextMenu {

                        Button {
                            Task { await miniAppManager.duplicate(app) }
                        } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }

                        Button {
                            Task { await miniAppManager.delete(app) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            Task {
                                do {
                                    exportURL = try await miniAppManager.export(app)
                                    isExporting = true
                                } catch {
                                    print("Export error:", error)
                                }
                            }
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationTitle("NovaX")

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            .sheet(isPresented: $isPresentingNew) {
                NewMiniAppView()
            }

            .sheet(isPresented: $isExporting) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }

            .onChange(of: deepLinkTarget) { target in
                if let target = target {
                    navigationPath.append(target)
                    DispatchQueue.main.async {
                        deepLinkTarget = nil
                    }
                }
            }

            .navigationDestination(for: MiniApp.self) { app in
                MiniAppDetailView(app: app)
            }
        }
    }
}
