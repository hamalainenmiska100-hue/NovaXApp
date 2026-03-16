import SwiftUI

/// A view modifier that applies a Liquid Glass effect to a view.
///
/// On iOS 26 and later this uses the native `glassEffect` modifier introduced
/// with Liquid Glass【698973894277683†L353-L371】.  On earlier systems the
/// modifier falls back to a translucent material with a subtle stroke and
/// gradient to approximate the appearance【951004573568146†L75-L140】.  Use this
/// modifier on surfaces that float above content such as toolbars, tab bars
/// and floating panels【910720439963727†L24-L73】.
struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 26.0, *) {
                content
                    // Use the default interactive glass effect which adapts
                    // to its background.  The shape is inferred from the
                    // surrounding layout so we do not specify an explicit
                    // shape here.
                    .glassEffect()
            } else {
                content
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    // Add a subtle linear gradient to mimic specular highlights
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0.0)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.overlay)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    )
            }
        }
    }
}

extension View {
    /// Applies a Liquid Glass appearance to the view.  For earlier OS
    /// versions the effect approximates Liquid Glass using materials and
    /// gradients.
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}