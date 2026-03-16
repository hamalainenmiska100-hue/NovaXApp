import SwiftUI

/// Presents the contents of a single mini‑app file.
///
/// The source code is displayed using a monospaced font and scrolls
/// vertically.  A simple copy button is provided on the toolbar to allow
/// quick copying of the file’s contents to the clipboard.
struct FileDetailView: View {
    let file: MiniFile
    @State private var didCopy = false

    var body: some View {
        ScrollView {
            Text(file.content)
                .font(.system(.body, design: .monospaced))
                .padding()
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: copyToClipboard) {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                }
                .accessibilityLabel("Copy source code")
            }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = file.content
        withAnimation {
            didCopy = true
        }
        // Reset the icon after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                didCopy = false
            }
        }
    }
}