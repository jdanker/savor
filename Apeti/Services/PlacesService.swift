//
//  PlacesService.swift
//  Apeti
//
//  Created by Jahred Danker on 12/22/25.
//

import Foundation
import GooglePlacesSwift

@MainActor
final class PlacesService {
    // MARK: - Properties
    private let client: PlacesClient
    private var sessionToken: AutocompleteSessionToken?

    // MARK: - Initialization
    // Use optional parameter so we can default inside MainActor context
    init(client: PlacesClient? = nil) {
        self.client = client ?? PlacesClient.shared
    }


    // MARK: - Public Methods

    /// Search for restaurant suggestions based on user query
    /// - Parameter query: The search string from the user
    /// - Returns: Result containing array of suggestions or error
    func searchRestaurants(query: String) async -> Result<[AutocompletePlaceSuggestion], Error> {
        // TODO(human): Implement autocomplete search logic
        // 1. Create or reuse session token (check if sessionToken is nil, create new AutocompleteSessionToken if needed)
        // 2. Set up AutocompleteRequest with the query and session token
        // 3. Configure filter to include only restaurant types (.restaurant, .cafe, .bar, .bakery)
        // 4. Use do-catch to call client.fetchAutocompleteSuggestions(with: request)
        // 5. Return Result.success with suggestions array or Result.failure with caught error

        return .success([])
    }

    /// Fetch full place details for a selected suggestion
    /// - Parameter placeID: The Google place ID
    /// - Returns: Result containing Place object or error
    func fetchPlaceDetails(placeID: String) async -> Result<Place, Error> {
        do {
            // Request only the fields we need to minimize API costs
            let fields: [PlaceProperty] = [.displayName, .rating, .priceLevel, .types]

            let request = FetchPlaceRequest(placeID: placeID, placeProperties: fields)
            let result: Result<Place, PlacesError> = try await client.fetchPlace(with: request)
            let place = try result.get()

            // Invalidate session token after successful fetch (billing optimization)
            resetSession()

            return .success(place)
        } catch {
            resetSession()
            return .failure(error)
        }
    }

    /// High-level method: converts a suggestion into a Restaurant model
    /// - Parameter suggestion: The selected autocomplete suggestion
    /// - Returns: Result containing Restaurant or error
    func createRestaurant(from suggestion: AutocompletePlaceSuggestion) async -> Result<Restaurant, Error> {
        // First fetch full place details
        let detailsResult = await fetchPlaceDetails(placeID: suggestion.placeID)

        switch detailsResult {
        case .success(let place):
            // TODO(human): Implement mapping logic from Google Place to Restaurant model
            // 1. Extract displayName (or use suggestion.title as fallback)
            // 2. Extract rating (default to 0.0 if nil)
            // 3. Extract priceLevel (can be nil)
            // 4. Extract primaryType from types array (use first type or "restaurant" as default)
            // 5. Create and return Restaurant object

            let restaurant = Restaurant(
                placeID: suggestion.placeID,
                name: "TODO",
                rating: 0.0,
                primaryType: "restaurant",
                priceLevel: nil
            )
            return .success(restaurant)

        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Private Helpers

    /// Reset the session token (called after place selection)
    private func resetSession() {
        sessionToken = nil
    }
}

