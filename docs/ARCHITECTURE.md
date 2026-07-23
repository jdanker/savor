# Savor (iOS) — Architecture

SwiftUI + Observation framework, iOS 26+, MVVM-ish with a single observable app-state
object. No Combine, no third-party state management. UIKit only where the Places SDK
requires `UIImage`.

## Structure

```mermaid
flowchart TD
    App[SavorApp<br/>entry, SDK key init] --> State[AppState<br/>@Observable @MainActor<br/>single source of truth]
    State --> Store[RestaurantStore<br/>JSON file persistence]
    State --> Proto[PlacesProviding protocol]
    Proto --> Svc[PlacesService<br/>Google Places SDK impl]
    State --> Loc[LocationService<br/>one-shot fix]
    App --> Tabs[RootTabView] --> Views[HomeListView / AddRestaurantView /<br/>RestaurantDetailView / PhotoCarouselView]
    Views -->|read + call mutations| State
```

Key invariants:
- **All mutations go through `AppState`** and persist immediately via `store.save` —
  no dirty/batched-save state exists.
- **`PlacesProviding` is the backend seam.** No Google SDK type crosses it; swapping
  the SDK for the Go proxy (Phase 1) is a change to one default argument in `AppState.init`.
- **Two-tier data fetching** (billing): cheap fields on save (`createRestaurant`),
  expensive fields on demand (`refreshRestaurant`, gated by 30-day `needsRefresh`).

## Code Map
<!-- Rule: every new file gets one line here, in the same change that creates it. -->

### Savor/ (app root)
- `SavorApp.swift` — entry point; reads Places key from Info.plist, initializes both Google SDKs, injects `AppState`
- `Info.plist` — Places key via `$(GOOGLE_PLACES_API_KEY)` from Secrets.xcconfig; location usage string
- `PrivacyInfo.xcprivacy` — privacy manifest (UserDefaults access reason only)

### Views/
- `RootTabView.swift` — tab shell (currently List tab only)
- `HomeListView.swift` — saved list; sort as a view-level projection (manual/price/rating/distance), swipe actions, drag-reorder (manual sort only), delete maps displayed offsets → stable IDs
- `AddRestaurantView.swift` — search sheet; 300ms debounced autocomplete through AppState's shared service, viewState enum (idle/loading/error/noResults/results)
- `RestaurantDetailView.swift` — detail sheet; lazy enrichment via `.task` + `needsRefresh`, fractional star rendering
- `PhotoCarouselView.swift` — horizontal photo scroll; skips fetch for `preview.` placeIDs

### ViewModels/
- `AppState.swift` — `@Observable @MainActor`; owns `[Restaurant]`, all mutations, autocomplete/photo passthroughs, distance-sort prep + coordinate backfill

### Models/
- `Restaurant.swift` — the only domain model; Codable straight to JSON, type-display priority ranking, price/icon helpers, `needsRefresh`, preview data

### Services/
- `PlacesProviding.swift` — protocol seam + `PlaceSuggestion` domain type; doc-comments the two-tier cost contract
- `PlacesService.swift` — Google SDK impl; session tokens, field masks, L1 NSCache → L2 disk → L3 API photo cache
- `LocationService.swift` — one-shot location via `CLLocationUpdate.liveUpdates`

### Storage/
- `RestaurantStore.swift` — thin JSON wrapper (`Documents/restaurants.json`), ISO-8601 dates; load failures return `[]`

### Theme/
- `SavorTheme.swift` — color palette, `SavorBackground`, `.savorCardStyle()` card modifier

## Integration boundary (Phase 1 target)
Today the app calls Google directly. Phase 1 replaces `PlacesService` with a
`PlacesProviding` impl that calls savor-api; the API key leaves the device.
See `savor-api/docs/ARCHITECTURE.md` for the server side.
