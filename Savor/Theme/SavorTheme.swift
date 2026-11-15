import SwiftUI
import UIKit

/// The app palette. Every token resolves per appearance (light / dark) at render
/// time, so views just read `SavorTheme.x` and adapt automatically.
///
/// Defined in code rather than Asset Catalog color sets on purpose: the whole
/// palette, light and dark side by side, stays in one reviewable Swift file, so a
/// git diff shows exactly which values changed (asset catalogs scatter it across
/// one JSON file per color). See decisions.md.
///
/// Rule: views never use raw `Color.white` / `Color.black` for surfaces or text;
/// add a token here instead. (White glyphs on an accent-filled shape are fine:
/// they read in both modes.)
enum SavorTheme {
    // Surfaces
    static let background = Color(
        light: Color(red: 0.89, green: 0.89, blue: 0.87),
        dark: Color(red: 0.11, green: 0.11, blue: 0.105)   // warm charcoal, not pure black
    )
    /// Cards (restaurant rows, detail sections, list rows)
    static let cardFill = Color(light: .white.opacity(0.62), dark: .white.opacity(0.07))
    /// Hairline edge on cards, photos and fields
    static let cardStroke = Color(light: .white.opacity(0.42), dark: .white.opacity(0.08))
    /// Small capsules and placeholders (Website / Been tags, photo placeholder)
    static let chipFill = Color(light: .white.opacity(0.55), dark: .white.opacity(0.10))
    /// Text-entry surfaces (Add sheet search bar): a touch more opaque than chips
    static let fieldFill = Color(light: .white.opacity(0.72), dark: .white.opacity(0.12))
    /// Soft lift under cards. Dropped in dark mode: a dark shadow on a dark
    /// background doesn't read, and the lighter card fill already separates it.
    static let cardShadow = Color(light: .black.opacity(0.06), dark: .clear)

    // Brand + semantic. The dark variants are lifted for contrast on charcoal,
    // but accent stays dark enough that white glyphs on accent fills stay legible.
    static let accent = Color(
        light: Color(red: 0.28, green: 0.39, blue: 0.55),
        dark: Color(red: 0.47, green: 0.60, blue: 0.78)
    )
    /// Icon tiles behind white glyphs: muted in dark so they don't glare
    static let accentSoft = Color(
        light: Color(red: 0.55, green: 0.68, blue: 0.82),
        dark: Color(red: 0.33, green: 0.44, blue: 0.58)
    )
    static let olive = Color(
        light: Color(red: 0.33, green: 0.49, blue: 0.36),
        dark: Color(red: 0.52, green: 0.71, blue: 0.55)
    )
    static let gold = Color(
        light: Color(red: 0.89, green: 0.73, blue: 0.24),
        dark: Color(red: 0.93, green: 0.78, blue: 0.32)
    )
    static let rose = Color(
        light: Color(red: 0.73, green: 0.45, blue: 0.42),
        dark: Color(red: 0.87, green: 0.59, blue: 0.56)
    )

    // Text
    static let ink = Color(
        light: Color(red: 0.15, green: 0.16, blue: 0.17),
        dark: Color(red: 0.93, green: 0.93, blue: 0.91)
    )
    static let mutedInk = Color(
        light: Color(red: 0.36, green: 0.37, blue: 0.39),
        dark: Color(red: 0.66, green: 0.67, blue: 0.69)
    )
}

extension Color {
    /// A color that picks its light or dark value from the view's current
    /// appearance each time it renders. It wraps UIKit's dynamic-provider
    /// `UIColor`: the closure runs at resolve time with the current trait
    /// collection, so a `static let` token still follows the light/dark switch
    /// (and a per-view `.environment(\.colorScheme, …)` override).
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

struct SavorBackground: View {
    var body: some View {
        ZStack {
            SavorTheme.background
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

private struct SavorCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SavorTheme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(SavorTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: SavorTheme.cardShadow, radius: 16, x: 0, y: 8)
    }
}

extension View {
    func savorCardStyle() -> some View {
        modifier(SavorCardModifier())
    }
}
