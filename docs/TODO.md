# TODO
<!-- Actionable backlog. Prune ruthlessly; done items get deleted, not checked off
     forever. STATE.md is for awareness; this file is for work. -->

## Bugs
- [ ] `RestaurantDetailView.restaurant` force-unwraps `first(where:)` — crashes if
      the restaurant is deleted while its detail sheet is open. Return early /
      dismiss on nil instead.
- [ ] `AppState.commitAdd` trims `draftPlaceID` into a local, then saves the
      untrimmed value.

## Chores
- [ ] Remove legacy manual-entry draft properties from `AppState` once the
      autocomplete flow is fully trusted.
- [ ] Replace blanket `.claude/` gitignore with `.claude/settings.local.json` only;
      un-ignore `CLAUDE.md`.

## Phase 1
- [ ] `SavorAPIService: PlacesProviding` targeting savor-api (blocked on server
      endpoints existing).
