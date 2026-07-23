# Decisions
<!-- Append-only. One dated paragraph per non-obvious tradeoff. Newest at top. -->

**2026-07 — Sort is a view-level projection, never persisted.** The stored array
order always means "manual order"; price/rating/distance sorts are computed in
`HomeListView.sortedRestaurants` and never call `store.save`. Consequences: reorder
is disabled outside manual sort (it would snap back), and delete must map displayed
offsets to stable IDs before mutating.

**2026-07 — Coordinates stored as optional `Double`s, backfilled lazily.** Keeps
`Restaurant` Codable without conditional conformances, lets pre-1.2 saves decode
cleanly, and defers the (cheapest-SKU) coordinate fetch until the user actually
picks distance sort — no billing or permission prompt for a feature never used.

**2026-07 — `PlacesProviding` protocol as the backend seam.** Views and AppState
never see Google SDK types; `PlaceSuggestion` uses Foundation `AttributedString`
so SDK match-highlighting survives without leaking a Google type. Phase 1 (Go proxy)
becomes a new conforming type + one default-argument change.

**2026-07 — Two-tier field fetching for Places billing.** On save: cheap fields
only (name, rating, price, types, editorial summary, photos, website). On demand
(detail view, 30-day staleness gate): expensive fields like `reviewSummary`.
Autocomplete session tokens are reset after each detail fetch — session-based
pricing, not incidental.
