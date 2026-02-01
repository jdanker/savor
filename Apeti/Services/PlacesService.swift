//
//  PlacesService.swift
//  Apeti
//
//  Created by Jahred Danker on 12/22/25.
//

import Foundation
import GooglePlacesSwift
import UIKit

@MainActor
final class PlacesService {
    // MARK: - Properties
    private lazy var client: PlacesClient = PlacesClient.shared
    private var sessionToken: AutocompleteSessionToken?


    // MARK: - Public Methods

    /// Search for restaurant suggestions based on user query
    /// - Parameter query: The search string from the user
    /// - Returns: Result containing array of suggestions or error
    func searchRestaurants(query: String) async -> Result<[AutocompletePlaceSuggestion], Error> {
        if sessionToken == nil {
            sessionToken = AutocompleteSessionToken()
        }
        // Configure filter to include only restaurant types
        let filter = AutocompleteFilter(
            types: [.restaurant, .cafe, .bar, .bakery]
        )

        // Set up AutocompleteRequest with the query, session token, and filter
        let request = AutocompleteRequest(
            query: query,
            sessionToken: sessionToken,
            filter: filter
        )

        // Call the API and get the result
        let result = await client.fetchAutocompleteSuggestions(with: request)

        // Extract place suggestions and return
        switch result {
        case .success(let response):
            // TODO: Use compactMap to extract AutocompletePlaceSuggestion from .place cases
            let placeSuggestions = response.compactMap {
                suggestion -> AutocompletePlaceSuggestion?  in
                if case .place(let placeSuggestion) = suggestion {
                    return placeSuggestion
                }
                return nil
            }
            return .success(placeSuggestions)

        case .failure(let error):
            return .failure(error)
        }
    }

    /// Fetch full place details for a selected suggestion
    /// - Parameter placeID: The Google place ID
    /// - Returns: Result containing Place object or error
    func fetchPlaceDetails(placeID: String) async -> Result<Place, Error> {
        do {
            // Request only the fields we need to minimize API costs
            let fields: [PlaceProperty] = [
                .displayName,
                .rating,
                .priceLevel,
                .types,
                .editorialSummary,
                .photos
            ]

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
    
    /// Fetch photos for a place by re-fetching place details and loading images
    /// - Parameters:
    ///   - placeID: The Google place ID
    ///   - maxCount: Maximum number of photos to load (default 3)
    /// - Returns: Array of loaded UIImages (may be fewer than maxCount if unavailable)
    func fetchPhotos(placeID: String, maxCount: Int = 3) async -> [UIImage] {
        let detailsResult = await fetchPlaceDetails(placeID: placeID)

        guard case .success(let place) = detailsResult,
              let photos = place.photos, !photos.isEmpty else { return [] }

        let photosToFetch = Array(photos.prefix(maxCount))
        var images: [UIImage] = []

        for photo in photosToFetch {
            let request = FetchPhotoRequest(
                photo: photo,
                maxSize: CGSize(width: 800, height: 600)
            )
            let result = await client.fetchPhoto(with: request)
            if case .success(let image) = result {
                images.append(image)
            }
        }

        return images
    }

    /// High-level method: converts a suggestion into a Restaurant model
    /// - Parameter suggestion: The selected autocomplete suggestion
    /// - Returns: Result containing Restaurant or error
    func createRestaurant(from suggestion: AutocompletePlaceSuggestion) async -> Result<Restaurant, Error> {
        // First fetch full place details
        let detailsResult = await fetchPlaceDetails(placeID: suggestion.placeID)

        switch detailsResult {
        case .success(let place):
            // Extract fields from Place object
            let name = place.displayName ?? "Unknown"
            let rating = place.rating.map { Double($0) } ?? 0.0

            // Convert PriceLevel enum to Int? (nil, or 1-4 for $-$$$$)
            let priceLevel: Int? = {
                switch place.priceLevel {
                case .free, .unspecified:
                    return nil
                case .inexpensive:
                    return 1
                case .moderate:
                    return 2
                case .expensive:
                    return 3
                case .veryExpensive:
                    return 4
                @unknown default:
                    return nil  // Handle future price levels gracefully
                }
            }()

            // Convert Set<PlaceType> to [String]
            let types = place.types.map { $0.rawValue }

            // Extract editorial summary (may be nil)
            let editorialSummary = place.editorialSummary

            let restaurant = Restaurant(
                placeID: suggestion.placeID,
                name: name,
                rating: rating,
                types: types,
                priceLevel: priceLevel,
                editorialSummary: editorialSummary
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

