import SwiftUI

/// A view modifier that applies a glass-like effect to a view.
///
/// Since the current SDK (iOS 17) does not support Apple's future
/// Liquid Glass API, this modifier approximates the look using
/// materials, rounded corners, and highlights.
struct LiquidGlassModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .overlay(
                LinearGradient(
                    gradient: Gradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.0)
                        ]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.overlay)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            )
    }
}

extension View {

    /// Applies a glass-like floating surface appearance.
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}
