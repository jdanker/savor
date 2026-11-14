# Adaptive split layout (size classes, NavigationSplitView, iPhone Duo)

**What**: iPhone used to be reliably "compact width" (only Max models went
regular in landscape), so phone apps quietly assumed narrow layouts. iPhone Duo
breaks that: closed it's a compact phone, open its inner display is
regular-width, and folding switches between the two *while the app runs*. Apple's
rule for Duo is to choose layouts from **size classes or available space** and
never from `userInterfaceIdiom`, `UIScreen.main.bounds`, or device orientation.

SwiftUI pieces used here:

| Piece | Role |
|---|---|
| `@Environment(\.horizontalSizeClass)` | `.compact` / `.regular`; changes live on fold |
| `NavigationSplitView` | 2- or 3-column layout at regular width; collapses to a stack at compact |
| `preferredCompactColumn:` | which column shows when collapsed (pinned to `.sidebar` for 2-column tabs) |
| `List(selection:)` | sidebar selection fills the next column; becomes a push when collapsed |
| `containerRelativeFrame` | size a view as a fraction of its scroll/container width, not fixed points |

**Why here**: A restaurant shortlist is a list/detail app, the textbook split-view
case. On Duo's inner display, a half-height sheet over a stretched list wastes
most of the screen. The project-specific twist: we deliberately *don't* let the
split view collapse into push navigation at compact width. Detail stays a sheet
on phones, so `RestaurantDetailColumn` renders nothing at compact width (or the
collapsed stack would push it) and `.compactRestaurantSheet` takes over. Both
read one `Restaurant?` selection per tab, which is what makes fold/unfold
seamless. Anything new that presents restaurant detail should use this pair, not
a raw `.sheet`.

**Where**:
- `Savor/Views/AdaptiveRestaurantDetail.swift:23` — `RestaurantDetailColumn` (regular-only detail column)
- `Savor/Views/AdaptiveRestaurantDetail.swift:49` — `CompactRestaurantSheet`, incl. the unfold nil-write guard
- `Savor/Views/HomeListView.swift:61` — 2-column split, pinned compact column
- `Savor/Views/ListsTabView.swift:34` — 3-column split, `List(selection:)`
- `Savor/Views/PhotoCarouselView.swift:44` — container-relative photo tiles

**Gotchas**:
- Unfolding force-dismisses the sheet and SwiftUI writes `nil` through its
  binding. Without the guard in `sheetSelection`, the open restaurant is lost.
- `.scrollTargetBehavior(.viewAligned)` does nothing without `.scrollTargetLayout()`
  on the stack inside the scroll view.

**Deeper**: https://developer.apple.com/iphone-duo/prepare/
