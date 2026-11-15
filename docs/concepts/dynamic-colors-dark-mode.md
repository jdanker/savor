# Dynamic colors (light / dark mode)

**What**: iOS can switch appearance at any moment (Settings, Control Center,
sunset schedule), and system-drawn UI such as grouped list rows, section
headers, toolbar glass and sheets follows instantly. A hard-coded
`Color(red:green:blue:)` doesn't follow. If the app paints its own surfaces with
fixed colors but lets the system draw the rest, the two halves disagree: dark
system rows under fixed near-black text. The fix is colors that *resolve at
render time*. SwiftUI's `Color` can wrap a UIKit dynamic `UIColor`, whose
provider closure receives the current `UITraitCollection` and returns the right
variant. Because it's evaluated per render, not once at launch, a `static let`
token still switches live, and it respects a per-view
`.environment(\.colorScheme, …)` override.

**Why here**: Savor draws most of its own surfaces (background, cards, chips),
so all of them must come from adaptive tokens, or the app splits in two the
moment the user goes dark. The project rule: views read `SavorTheme` tokens and
never raw `Color.white` / `.black` for surfaces or text. White glyphs on an
accent fill are the exception, since they read in both modes. The palette lives
in code rather than an asset catalog so light and dark sit side by side in one
diff-friendly file (see decisions.md).

**Where**:
- `Savor/Theme/SavorTheme.swift:15` — the token palette (light + dark per token)
- `Savor/Theme/SavorTheme.swift:74` — `Color(light:dark:)` dynamic-provider helper
- `Savor/Views/ListsTabView.swift:61` — themed row fill for the one grouped system `List`

**Gotchas**:
- A system `List` row keeps the *system* background unless you set
  `.listRowBackground`. That was the original Lists-tab bug.
- Don't "fix" a dark-mode problem by forcing `.colorScheme(.light)` on a
  screen. It hides the bug and leaves that screen glaring in dark mode.

**Deeper**: https://developer.apple.com/documentation/uikit/uicolor/init(dynamicprovider:)
