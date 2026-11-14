# TODO
<!-- Actionable backlog. Prune ruthlessly; done items get deleted, not checked off
     forever. STATE.md is for awareness; this file is for work. -->

## Bugs
- [ ] `AppState.commitAdd` trims `draftPlaceID` into a local, then saves the
      untrimmed value.

## Lists (v1.3 follow-ups)
- [ ] `ListDetailView` has no Add button — the only way to fill a list is
      long-press from Spots/Search. Consider an add flow that files straight
      into the open list.
- [ ] Swipe-delete means "remove from list" in ListDetailView but "delete
      everywhere" in Spots — consider a visual hint (label/tint) so the
      distinction is discoverable.
- [ ] Tune `SmartCategory` type tables against real saved data; lunch/dinner
      price-level fallback is a first guess.
- [ ] `RestaurantDetailView` could offer list membership (same actions as the
      row context menu).

## Chores
- [ ] Remove legacy manual-entry draft properties from `AppState` once the
      autocomplete flow is fully trusted.
- [ ] Replace blanket `.claude/` gitignore with `.claude/settings.local.json` only;
      un-ignore `CLAUDE.md`.

## iPhone Duo
- [ ] App Store Connect: add iPhone Duo screenshots (required for all
      submissions from April 2027; also earns the "Made for iPhone Duo" badge).
- [ ] Highlight the selected row in split-view sidebars (RestaurantRow is a tap
      button, so there's no List selection styling yet).
- [ ] Verify photo carousel sizing with real photos in the wide detail column
      (seeded `preview.` places skip photo fetches).

## Phase 1
- [ ] `SavorAPIService: PlacesProviding` targeting savor-api (blocked on server
      endpoints existing).
