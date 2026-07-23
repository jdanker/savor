# Places autocomplete session tokens

**What**: Google bills autocomplete per *session*, not per keystroke — if all
autocomplete requests and the final place-details fetch share one
`AutocompleteSessionToken`. Without a token, every keypress is billed as a
standalone request.

**Why here**: The token lives in the one shared `PlacesService` instance and is
reset only after a successful details fetch. This is why views must go through
`AppState.searchRestaurants` instead of constructing their own service — a fresh
service per keystroke would mint a new session each time.

**Where**: `Services/PlacesService.swift` (`sessionToken`, `resetSession()`),
`ViewModels/AppState.swift` (`searchRestaurants` passthrough comment),
`Views/AddRestaurantView.swift` (`onChange` comment).

**Gotchas**:
- `refreshRestaurant` and `fetchCoordinate` deliberately do *not* touch the token —
  they're outside any autocomplete session.
- The 300ms debounce in `AddRestaurantView` reduces request count *within* a
  session; it's a separate cost lever from the token.

**Deeper**: https://developers.google.com/maps/documentation/places/web-service/session-tokens
