# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For product roadmap, phase status, and collaboration ground rules (this user is an experienced
DevOps engineer, newer to iOS/SwiftUI, using Claude as a learning-focused pair programmer), see
`AGENTS.md` in this directory — read it before doing any non-trivial work here. Key rules from
it: don't make sweeping changes silently, explain trade-offs before implementing, flag anti-patterns
instead of quietly fixing them, and never edit its "Developer Notes" section.

## Commands

Build and test via `xcodebuild` (scheme: `Savor`, project: `Savor.xcodeproj`):

```bash
# Build for the simulator
xcodebuild -project Savor.xcodeproj -scheme Savor -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run all tests (unit + UI)
xcodebuild -project Savor.xcodeproj -scheme Savor -destination 'platform=iOS Simulator,name=iPhone 17' test

# Run a single test (Swift Testing framework, not XCTest)
xcodebuild -project Savor.xcodeproj -scheme Savor -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:SavorTests/SavorTests/example
```

In practice, day-to-day iteration happens in Xcode itself (Cmd+R / Cmd+U) — reach for `xcodebuild`
mainly for scripted/CI-style verification.

Tests use the **Swift Testing** framework (`import Testing`, `@Test`, `#expect`), not XCTest —
`SavorTests/` currently has only a placeholder test; `SavorUITests/` has launch tests.

## Secrets

`Savor/Secrets.xcconfig` holds `GOOGLE_PLACES_API_KEY` and is gitignored. It's referenced from
`Info.plist` as `GooglePlacesAPIKey`, read in `SavorApp.swift` at launch, and used to initialize
both the legacy `GMSPlacesClient` and the new `PlacesClient` (GooglePlacesSwift) — the app
crashes at launch (`fatalError`) if the key is missing, so this file must exist locally before
building.

## Architecture

SwiftUI + the `@Observable` macro (Observation framework), iOS 26+, no UIKit except where the
Places SDK's photo APIs require `UIImage`. Single observable app-state object, no Combine, no
third-party state management.

```
SavorApp (entry point)
  → AppState (@Observable, @MainActor — single source of truth for UI)
      → RestaurantStore (JSON file persistence, Documents/restaurants.json)
      → PlacesService (@MainActor — all Google Places SDK calls)
  → RootTabView → HomeListView / AddRestaurantView / RestaurantDetailView
```

- **`AppState`** (`ViewModels/AppState.swift`) owns the `[Restaurant]` array and all mutations.
  Every mutation (add/remove/reorder/status change) immediately persists via `store.save(...)` —
  there is no separate "dirty" or batched-save state to reason about.
- **`RestaurantStore`** (`Storage/RestaurantStore.swift`) is a thin JSON-file wrapper — no
  database, no Core Data, no sync. Load failures (missing file, bad decode) silently return `[]`
  rather than surfacing an error.
- **`PlacesService`** (`Services/PlacesService.swift`) wraps `GooglePlacesSwift` and is the only
  place that talks to Google. Two data-fetch tiers by design (cost control, per `AGENTS.md`
  roadmap notes):
  - **On save**: cheap/"Pro" fields only (`displayName`, `rating`, `priceLevel`, `types`,
    `editorialSummary`, `photos`, `websiteURL`).
  - **On demand** (`refreshRestaurant`, called lazily from the detail view): "Enterprise" fields
    like `reviewSummary`, gated by `Restaurant.needsRefresh` (30-day staleness check).
  - Autocomplete uses `AutocompleteSessionToken`, reset after every place-detail fetch — this is
    a Google Places billing optimization (session-based autocomplete pricing), not incidental.
  - Photos use a two-tier cache: `NSCache` in memory (L1) → JPEGs on disk under
    `Caches/PlacePhotos/{placeID}_{n}.jpg` (L2) → Places SDK fetch (L3, then written back to
    both cache tiers).
- **`Restaurant`** (`Models/Restaurant.swift`) is the app's only domain model — `Codable`,
  mapped directly to/from JSON, no separate DTO layer. It carries Google's raw `types: [String]`
  and derives a human-readable primary type (`primaryTypeDisplay`) via a hand-tuned priority
  ranking (specific cuisine types outrank generic ones like `"restaurant"` or
  `"point_of_interest"`) rather than trusting array order from the API.

## Integration boundary (important, easy to get wrong)

The iOS app currently calls the Google Places SDK **directly** — there is no backend in the loop
yet, despite `savor-api` existing and being deployed. Don't assume requests are proxied through
Go unless you've checked; see the top-level `../CLAUDE.md` for the target architecture and
current gap.
