import SwiftUI
import UIKit

/// A SwiftUI wrapper around `UIActivityViewController` for sharing items.
///
/// Use this in combination with `sheet(isPresented:)` to present a share
/// sheet when exporting mini‑apps.  The items array can contain URLs,
/// strings or other activity items.  This wrapper hides the UIKit
/// implementation details from the rest of the SwiftUI code.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update.  The controller is recreated whenever the items change.
    }
}