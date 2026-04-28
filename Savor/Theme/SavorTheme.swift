import SwiftUI

enum SavorTheme {
    static let background = Color(red: 0.89, green: 0.89, blue: 0.87)
    static let cardFill = Color.white.opacity(0.62)
    static let cardStroke = Color.white.opacity(0.42)
    static let accent = Color(red: 0.28, green: 0.39, blue: 0.55)
    static let accentSoft = Color(red: 0.55, green: 0.68, blue: 0.82)
    static let olive = Color(red: 0.33, green: 0.49, blue: 0.36)
    static let gold = Color(red: 0.89, green: 0.73, blue: 0.24)
    static let rose = Color(red: 0.73, green: 0.45, blue: 0.42)
    static let ink = Color(red: 0.15, green: 0.16, blue: 0.17)
    static let mutedInk = Color(red: 0.36, green: 0.37, blue: 0.39)
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
            .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func savorCardStyle() -> some View {
        modifier(SavorCardModifier())
    }
}
