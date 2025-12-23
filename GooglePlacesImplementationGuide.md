# Google Places Autocomplete Implementation Guide

## Overview

You'll be replacing the manual restaurant form with a Google Places Autocomplete search interface. When users select a restaurant from suggestions, it will immediately save to their list.

**Learning Goals:**
- Understand how to integrate Google Places SDK in SwiftUI
- Learn async/await patterns with @Observable state management
- Implement debounced search for better UX and API efficiency
- Handle API errors gracefully

---

## Prerequisites

✅ Google Places SDK already installed via SPM (v10.6.0)
✅ You have a Google Places API key ready
✅ Restaurant model already has the right fields (placeID, name, rating, primaryType, priceLevel)

---

## Architecture Overview

**Current Flow:**
```
User taps + → Sheet opens → Manual form → Fill fields → Save
```

**New Flow:**
```
User taps + → Sheet opens → Search box → Type query → Select suggestion → Auto-save & dismiss
```

**Key Architectural Decision:**

Instead of putting all the Google Places API logic directly in your view or AppState, you'll create a **Service Layer** (`PlacesService`). This is a common iOS pattern that:
- Separates API concerns from UI state
- Makes testing easier (you can mock the service)
- Keeps your code organized and reusable

---

## Implementation Steps

### Step 1: Initialize the Google Places SDK

**File:** `Apeti/ApetiApp.swift`

**What you need to do:**
1. Import `GooglePlacesSwift` at the top
2. In the `init()` method, call `PlacesClient.provideAPIKey("YOUR_API_KEY")`

**Key Concept:** The Places SDK must be initialized before any API calls. The app's `init()` is the perfect place since it runs once at startup.

**Security Note:** Hardcoding the API key works for development, but for production you should:
- Use a `.xcconfig` file (add to `.gitignore`)
- Or use environment variables
- Restrict the key in Google Cloud Console to your bundle ID

**Documentation:** [Set up the Places SDK for iOS](https://developers.google.com/maps/documentation/places/ios-sdk/get-api-key)

---

### Step 2: Create a Places Service Layer

**New File:** `Apeti/Services/PlacesService.swift`

**What this service should do:**

1. **Fetch autocomplete suggestions**
   - Takes a search query string
   - Returns a list of suggestions filtered to restaurants only
   - Uses session tokens for billing optimization

2. **Fetch full place details**
   - Takes a placeID from a selected suggestion
   - Fetches the complete data (rating, price level, etc.)
   - Returns enough info to create a Restaurant model

3. **Helper method: Convert suggestion → Restaurant**
   - Combines steps 1 and 2
   - Maps Google's Place object to your Restaurant model

**Key Concepts to Learn:**

**Session Tokens:** Google uses these to track a search session (query → selection). You create one token, use it for all autocomplete requests, then invalidate it after fetching place details. This reduces billing costs.

**Type Filtering:** Use `AutocompleteFilter` to restrict results to:
- `.restaurant`
- `.cafe`
- `.bar`
- `.bakery`
- `.foodEstablishment`

**Field Masks:** When fetching place details, only request the fields you need:
- `displayName`
- `rating`
- `priceLevel`
- `types`

This reduces response size and API costs.

**Async/await:** All API calls are asynchronous. Use `async` functions that return `Result<T, Error>` for clean error handling.

**Structure Template:**
```swift
import GooglePlacesSwift

@MainActor
final class PlacesService {
    private let client: PlacesClient
    private var sessionToken: AutocompleteSessionToken?

    // Method 1: fetchAutocompleteSuggestions(query: String) async -> Result<[Suggestion], Error>
    // Method 2: fetchPlaceDetails(placeID: String) async -> Result<PlaceDetails, Error>
    // Method 3: createRestaurant(from: Suggestion) async -> Result<Restaurant, Error>
}
```

**Documentation:**
- [Place Autocomplete (New)](https://developers.google.com/maps/documentation/places/ios-sdk/place-autocomplete)
- [PlacesClient Reference](https://developers.google.com/maps/documentation/places/ios-sdk/reference/swift/Classes/PlacesClient)

---

### Step 3: Update AppState for Autocomplete

**File:** `Apeti/ViewModels/AppState.swift`

**Changes needed:**

1. **Add a PlacesService dependency**
   ```swift
   private let placesService: PlacesService
   ```

2. **Add new state properties:**
   - `searchQuery: String` - bound to the search textfield
   - `isLoadingPlaceDetails: Bool` - shows spinner while fetching
   - `placesError: String?` - displays error messages

3. **Add new method: `selectPlace(suggestion:)`**
   - This is async (calls the service)
   - Shows loading state
   - On success: creates Restaurant, inserts at front, saves, dismisses sheet
   - On failure: shows error, keeps sheet open

4. **Update `cancelAdd()`**
   - Clear searchQuery
   - Clear error
   - Dismiss sheet

**Key Concept - @MainActor:** Your AppState is marked `@MainActor`, which means all its methods run on the main thread. This is perfect for UI updates. When you call async methods, SwiftUI will automatically update the UI when state changes.

**You can remove the old draft properties** (draftName, draftType, etc.) since you're no longer using a manual form. Keep `isPresentingAdd` for showing/hiding the sheet.

---

### Step 4: Replace AddRestaurantView with Autocomplete UI

**File:** `Apeti/Views/AddRestaurantView.swift`

This is the biggest change. You'll replace the entire form with a search interface.

**UI Components you need:**

1. **Search TextField**
   - Bound to `state.searchQuery`
   - Placeholder: "Search for a restaurant..."
   - Include a clear button (X) when text is present

2. **Suggestions List**
   - Use a SwiftUI `List` showing autocomplete results
   - Each row is a Button that calls `state.selectPlace(suggestion)`
   - Show suggestion name and full description

3. **Loading State**
   - Show `ProgressView` when `state.isLoadingPlaceDetails` is true
   - Display "Loading restaurant details..." text

4. **Error State**
   - Show banner with `state.placesError` if present
   - Use orange/yellow color to indicate warning

5. **Empty State**
   - When search returns no results
   - Use `ContentUnavailableView` with magnifying glass icon

**Key Implementation Detail - Debouncing:**

When the user types, you don't want to hit the API on every keystroke. Instead:
1. Use `.onChange(of: state.searchQuery)` to detect typing
2. Cancel any previous search task
3. Wait 300ms before actually searching
4. If user keeps typing, cancel and restart the timer

This is called "debouncing" and it dramatically reduces API calls.

**Implementation Pattern:**
```swift
@State private var searchTask: Task<Void, Never>?

.onChange(of: state.searchQuery) { old, new in
    searchTask?.cancel()

    searchTask = Task {
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        // Now actually perform the search
        let results = await placesService.fetchAutocompleteSuggestions(...)
        // Update your local @State with results
    }
}
```

**Note:** You'll need a local `@State` variable in the view to hold the suggestions array, since those are UI-only (not part of AppState).

**Documentation:** [SwiftUI Task management](https://developer.apple.com/documentation/swift/task)

---

### Step 5: Fix Existing Bug

**File:** `Apeti/Views/HomeListView.swift` (line 21)

There's a bug where the code references `restaurant.type` but the model property is `restaurant.primaryType`.

**Change:**
```swift
// BEFORE:
Text("\(restaurant.type) • \(state.levelString(restaurant.priceLevel))")

// AFTER:
Text("\(restaurant.primaryType) • \(state.levelString(restaurant.priceLevel))")
```

This will prevent compilation errors.

---

## Error Handling Strategy

Think about what can go wrong:

1. **Network is down**
   - Show: "Unable to connect. Check your internet."
   - Recovery: User can try again

2. **API key is invalid**
   - Show: "Service unavailable. Try again later."
   - Log detailed error to console for debugging
   - Recovery: Fix API key, restart app

3. **Place is missing data** (no rating, no price level)
   - Use defaults: rating = 0.0, priceLevel = nil
   - Don't crash, just save what you have

4. **User selects invalid place**
   - Show: "Could not load restaurant details."
   - Keep sheet open so they can try another

**Pattern:** Use `Result<Success, Failure>` types in your service, then `switch` on the result in AppState to handle success vs error.

---

## Testing Your Implementation

**Manual Testing Checklist:**

1. ✓ Search with "pizza" → should show pizza restaurants
2. ✓ Search with "skldjfh" → should show "No results"
3. ✓ Select a suggestion → should show loading, then save and dismiss
4. ✓ Turn off WiFi and search → should show error
5. ✓ Type quickly and delete → should not spam API (debouncing works)
6. ✓ Cancel button → should dismiss and clear state

**Advanced:** Write unit tests for PlacesService by mocking the PlacesClient

---

## Key Files to Modify

1. **`Apeti/ApetiApp.swift`** - Initialize Places SDK
2. **`Apeti/Services/PlacesService.swift`** - NEW: Create service layer
3. **`Apeti/ViewModels/AppState.swift`** - Add autocomplete methods
4. **`Apeti/Views/AddRestaurantView.swift`** - Replace with search UI
5. **`Apeti/Views/HomeListView.swift`** - Fix type → primaryType bug

---

## Learning Resources

- [Google Places Swift SDK Overview](https://developers.google.com/maps/documentation/places/ios-sdk/google-places-swift)
- [Swift Concurrency (async/await)](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [SwiftUI State Management](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
- [Sample Code: iOS Places SDK](https://github.com/googlemaps-samples/ios-places-sdk-samples)

---

## Common Pitfalls to Avoid

❌ **Don't** hardcode API key in production (security risk)
❌ **Don't** forget to filter autocomplete to restaurant types (users will see random places)
❌ **Don't** make API calls on every keystroke (expensive and slow)
❌ **Don't** forget to handle missing data (rating/priceLevel might be nil)
❌ **Don't** forget to invalidate session tokens after fetching details (billing optimization)

✅ **Do** use debouncing (300ms delay)
✅ **Do** show loading and error states
✅ **Do** use session tokens correctly
✅ **Do** only request the fields you need (field masks)
✅ **Do** create a service layer for clean architecture

---

## Next Steps After This Feature

Once autocomplete is working, you mentioned wanting to build a **restaurant detail page view**. That will involve:
- Creating a new detail view
- Passing the selected Restaurant to it
- Displaying full info (name, rating, price, maybe photos)
- Possibly fetching more details from Places API (reviews, photos, hours)

But that's for later! Focus on getting autocomplete working first.

---

## Questions to Consider

As you implement, think about:

1. **Where should PlacesService be created?**
   - Singleton vs injected dependency?
   - I recommend dependency injection (pass to AppState) for testability

2. **Should search results be cached?**
   - Could save API calls if user goes back to same search
   - Trade-off: added complexity vs cost savings

3. **What happens if a restaurant is already in the list?**
   - Should you prevent duplicates?
   - Check by placeID before saving?

These aren't critical for v1, but good to think about!

---

**Good luck! Start with Step 1 (API key initialization) and work through sequentially. Each step builds on the previous one.**
