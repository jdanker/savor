# STATE
<!-- Overwritten at the end of every working session. Keep under ~20 lines. -->
_Last updated: 2026-11-14_

## Works now (v1.3 + iPhone Duo branch `feature/iphone-duo-support`)
- Tabs Spots / Lists / Search, each a NavigationSplitView: detail in a column at
  regular width (Duo open), medium/large sheet at compact (Duo closed, iPhones)
- Lists tab is 3-column (lists → list → restaurant), driven by `List(selection:)`
- Built with the iOS 27.2 SDK: edge-to-edge on Duo, vertical tab bar/toolbar
- Detail no longer crashes if the spot is deleted while open ("Spot Removed")
- Photo carousel tiles size to the container (7:5, 80% width, max 420pt)

## In flight
- Duo open-pose (inner display) visual check pending: closed pose, build, and
  unit tests verified on the iPhone Duo sim (iOS 27.2 runtime). Pose switching
  needs the Simulator Device menu.

## Next
1. Duo follow-ups in TODO.md (App Store screenshots due April 2027)
2. Lists follow-ups; Phase 1 `SavorAPIService: PlacesProviding`

## Landmines
- Present restaurant detail only via `RestaurantDetailColumn` +
  `.compactRestaurantSheet` — a raw `.sheet` breaks fold/unfold handoff
- Never branch layout on idiom / `UIScreen.main` / orientation (Duo guidance)
- Tests run in parallel — file-touching tests need TestSupport.makeTempStore
- Sort projection is shared as `SortOption.apply` — defined in HomeListView.swift
