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
/// add a token here instead. That includes glyphs and labels on an accent fill:
/// use `onAccent`, because the dark-mode accent is light and needs dark text.
enum SavorTheme {
    // Surfaces
    static let background = Color(
        light: Color(hex: 0xFBEEDF),   // peach sand
        dark: Color(hex: 0x211712)     // dark roast, not pure black
    )
    /// Anything that sits on the background: cards, list rows, chips, fields.
    /// Opaque (the 1.x cards were translucent) so cards read the same over any
    /// content scrolling behind them.
    static let surface = Color(light: .white, dark: Color(hex: 0x30221B))
    /// Soft warm lift under cards. Dropped in dark mode: a dark shadow on a dark
    /// background doesn't read, and the lighter surface already separates it.
    static let cardShadow = Color(light: Color(hex: 0x78461E).opacity(0.10), dark: .clear)

    // Brand + semantic. In dark mode both fills get lighter, so anything drawn
    // on top of them must use `onAccent` rather than white.
    static let accent = Color(
        light: Color(hex: 0xB84A24),   // terracotta
        dark: Color(hex: 0xF0916A)
    )
    /// Text and glyphs on an `accent` or `olive` fill
    static let onAccent = Color(light: .white, dark: Color(hex: 0x211712))
    static let olive = Color(
        light: Color(hex: 0x55683A),
        dark: Color(hex: 0xA9BD82)
    )

    // Text
    static let ink = Color(
        light: Color(hex: 0x33241C),
        dark: Color(hex: 0xF8EBDD)
    )
    static let mutedInk = Color(
        light: Color(hex: 0x6F5A4D),
        dark: Color(hex: 0xC7B2A2)
    )
}

extension SavorTheme {
    /// The soft fill behind an icon tile, paired with the glyph color that reads
    /// on it. An enum (not three loose colors) so fill and glyph can't be mixed
    /// across tints, and so the symbol mapping below is testable by case.
    enum Tint: CaseIterable {
        case peach
        case sage
        case butter

        var fill: Color {
            switch self {
            case .peach: Color(light: Color(hex: 0xF8D9C4), dark: Color(hex: 0x4A2A1C))
            case .sage: Color(light: Color(hex: 0xDDE5C8), dark: Color(hex: 0x33402A))
            case .butter: Color(light: Color(hex: 0xF9E3A8), dark: Color(hex: 0x4A3A14))
            }
        }

        var glyph: Color {
            switch self {
            case .peach: SavorTheme.accent
            case .sage: SavorTheme.olive
            case .butter: Color(light: Color(hex: 0x7A5810), dark: Color(hex: 0xE8C465))
            }
        }
    }

    /// Picks the tile tint for an SF Symbol name (`Restaurant.iconName`,
    /// `RestaurantList.iconName`).
    ///
    /// Derived here from the symbol instead of stored on the model: a stored
    /// tint would be a new persisted `Codable` field for something that is pure
    /// presentation. Unknown symbols fall back to peach, so a new icon never
    /// needs a theme change to render.
    static func tint(forSymbol symbolName: String) -> Tint {
        switch symbolName {
        case "fish.fill", "wineglass.fill":
            .sage
        case "cup.and.saucer.fill", "sunrise.fill", "sun.max.fill":
            .butter
        default:
            .peach
        }
    }
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

    /// An opaque sRGB color from a `0xRRGGBB` literal. Hex (rather than 0–1
    /// components) so palette values can be compared character for character
    /// with the design sheet.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
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
                    .fill(SavorTheme.surface)
            )
            .shadow(color: SavorTheme.cardShadow, radius: 16, x: 0, y: 8)
    }
}

extension View {
    func savorCardStyle() -> some View {
        modifier(SavorCardModifier())
    }
}
