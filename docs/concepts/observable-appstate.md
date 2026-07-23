# @Observable + single AppState

**What**: The Observation framework's `@Observable` macro makes a class's stored
properties trackable — SwiftUI views re-render only when a property they *actually
read* changes. Replaces `ObservableObject`/`@Published`/Combine with finer-grained,
lower-boilerplate tracking.

**Why here**: One `@Observable @MainActor` class (`AppState`) is the single source
of truth; views read it via `@Environment` and call its mutation methods. Every
mutation persists immediately (`store.save`) so there's no dirty-state machinery.
`@MainActor` on the class makes all state access main-thread-safe by construction —
matters because Swift 6 concurrency checking is strict.

**Where**: `ViewModels/AppState.swift` (class), `SavorApp.swift:15` (injection via
`.environment`), any view's `@Environment(AppState.self)`.

**Gotchas**:
- Two-way bindings to `@Observable` objects need `@Bindable` (see `HomeListView.body`
  and `AddRestaurantView.searchBar` — `@Bindable var state = state`).
- Default arguments evaluate in a nonisolated context, so `= PlacesService()` can't
  be a default value for a `@MainActor` init — hence the nil-default pattern in
  `AppState.init`.

**Deeper**: https://developer.apple.com/documentation/observation
