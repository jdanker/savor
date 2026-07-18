//
//  PlacesProviding.swift
//  Savor
//

import CoreLocation
import UIKit

/// Domain-level autocomplete result. Deliberately not Google's AutocompletePlaceSuggestion —
/// each backend (Places SDK today, the Go proxy in Phase 1) maps its native type into this,
/// so no Google SDK types leak past the service boundary.
///
/// Text fields are AttributedString (Foundation, not a Google type) so the SDK's
/// query-match highlighting survives; a plain-string backend can wrap with
/// AttributedString(_:).
struct PlaceSuggestion: Identifiable, Hashable {
    let placeID: String
    let primaryText: AttributedString
    let fullText: AttributedString

    var id: String { placeID }
}

/// The seam between the app and whatever backend resolves place data.
///
/// Implementations own their session/billing strategy (SDK autocomplete session tokens,
/// proxy-side caching) — callers never see it. The two-tier cost model is part of the
/// contract: createRestaurant fetches only cheap "on save" fields; refreshRestaurant
/// fetches the expensive "on demand" fields.
@MainActor
protocol PlacesProviding {
    /// Autocomplete as the user types.
    func searchRestaurants(query: String) async -> Result<[PlaceSuggestion], Error>

    /// Resolves a suggestion into a full Restaurant (cheap fields only).
    func createRestaurant(from suggestion: PlaceSuggestion) async -> Result<Restaurant, Error>

    /// Re-fetches enrichable fields (website, review summary) — returns an updated copy.
    func refreshRestaurant(_ restaurant: Restaurant) async -> Result<Restaurant, Error>

    /// Coordinate-only lookup, used to backfill restaurants saved before lat/lng was stored.
    func fetchCoordinate(placeID: String) async -> CLLocationCoordinate2D?

    /// Photos for a place; implementations are expected to cache.
    func fetchPhotos(placeID: String, maxCount: Int) async -> [UIImage]
}

extension PlacesProviding {
    /// Protocols can't declare default arguments, so the maxCount default lives here.
    func fetchPhotos(placeID: String) async -> [UIImage] {
        await fetchPhotos(placeID: placeID, maxCount: 3)
    }
}
