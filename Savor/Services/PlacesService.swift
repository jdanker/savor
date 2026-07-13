//
//  PlacesService.swift
//  Savor
//
//  Created by Jahred Danker on 12/22/25.
//

import CoreLocation
import Foundation
import GooglePlacesSwift
import UIKit

@MainActor
final class PlacesService {
    // MARK: - Properties
    private lazy var client: PlacesClient = PlacesClient.shared
    private var sessionToken: AutocompleteSessionToken?

    // L1: Memory cache — keyed by placeID, auto-evicts under memory pressure
    private static let photoCache = NSCache<NSString, PhotoCacheEntry>()

    // L2: Disk cache — persists across app launches
    private static let photoCacheDir: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent("PlacePhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()


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
                .photos,
                .websiteURL,
                .coordinate  // Essentials tier — doesn't bump the request into a pricier SKU
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
    
    /// Returns cached photos (memory → disk → API) or fetches fresh
    func fetchPhotos(placeID: String, maxCount: Int = 3) async -> [UIImage] {
        let cacheKey = placeID as NSString

        // L1: Check memory cache
        if let cached = Self.photoCache.object(forKey: cacheKey) {
            return cached.images
        }

        // L2: Check disk cache
        if let diskImages = Self.loadFromDisk(placeID: placeID), !diskImages.isEmpty {
            // Promote back to memory cache for fast subsequent access
            Self.photoCache.setObject(PhotoCacheEntry(diskImages), forKey: cacheKey)
            return diskImages
        }

        // L3: Fetch from API
        let detailsResult = await fetchPlaceDetails(placeID: placeID)
        guard case .success(let place) = detailsResult,
              let photos = place.photos else { return [] }

        return await loadAndCachePhotos(photos, placeID: placeID, maxCount: maxCount)
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

            // Extract editorial summary and website (may be nil)
            let editorialSummary = place.editorialSummary
            let websiteURL = place.websiteURL

            // place.location is non-optional in the SDK — it returns an invalid sentinel
            // rather than nil when absent, so validate instead of storing (0, 0)
            let coordinate = CLLocationCoordinate2DIsValid(place.location) ? place.location : nil

            let restaurant = Restaurant(
                placeID: suggestion.placeID,
                name: name,
                rating: rating,
                types: types,
                priceLevel: priceLevel,
                editorialSummary: editorialSummary,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude,
                websiteURL: websiteURL
            )

            // Pre-cache photos in background — don't block restaurant creation
            if let photos = place.photos, !photos.isEmpty {
                Task { [weak self] in
                    await self?.loadAndCachePhotos(photos, placeID: suggestion.placeID)
                }
            }

            return .success(restaurant)

        case .failure(let error):
            return .failure(error)
        }
    }

    /// Re-fetches only enrichable fields (website, review summary) and returns an updated copy.
    /// Called lazily from the detail view — does not touch the autocomplete session token.
    func refreshRestaurant(_ restaurant: Restaurant) async -> Result<Restaurant, Error> {
        let fields: [PlaceProperty] = [.websiteURL, .reviewSummary]
        let request = FetchPlaceRequest(placeID: restaurant.placeID, placeProperties: fields)

        do {
            let result: Result<Place, PlacesError> = try await client.fetchPlace(with: request)
            let place = try result.get()

            var updated = restaurant
            updated.websiteURL = place.websiteURL
            updated.reviewSummary = place.reviewSummary?.text
            updated.lastRefreshedAt = Date()
            return .success(updated)
        } catch {
            return .failure(error)
        }
    }

    /// Fetches only the coordinate for a place — used to backfill restaurants saved before
    /// coordinates were stored. Coordinate-only requests are Essentials tier (cheapest SKU)
    /// and, like refreshRestaurant, don't touch the autocomplete session token.
    func fetchCoordinate(placeID: String) async -> CLLocationCoordinate2D? {
        let request = FetchPlaceRequest(placeID: placeID, placeProperties: [.coordinate])
        guard let result = try? await client.fetchPlace(with: request),
              case .success(let place) = result,
              CLLocationCoordinate2DIsValid(place.location) else { return nil }
        return place.location
    }

    // MARK: - Private Helpers

    /// Core photo loading logic — fetches images from Photo metadata and writes to both cache layers
    @discardableResult
    private func loadAndCachePhotos(_ photos: [Photo], placeID: String, maxCount: Int = 3) async -> [UIImage] {
        let cacheKey = placeID as NSString
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

        if !images.isEmpty {
            // L1: Memory cache
            Self.photoCache.setObject(PhotoCacheEntry(images), forKey: cacheKey)
            // L2: Disk cache
            Self.saveToDisk(images, placeID: placeID)
        }

        return images
    }

    // MARK: - Disk Cache

    /// Saves images as JPEG files: PlacePhotos/{placeID}_0.jpg, _1.jpg, etc.
    private static func saveToDisk(_ images: [UIImage], placeID: String) {
        for (index, image) in images.enumerated() {
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            let fileURL = photoCacheDir.appendingPathComponent("\(placeID)_\(index).jpg")
            try? data.write(to: fileURL)
        }
    }

    /// Loads cached images from disk for a given placeID
    private static func loadFromDisk(placeID: String) -> [UIImage]? {
        var images: [UIImage] = []
        for index in 0..<10 {
            let fileURL = photoCacheDir.appendingPathComponent("\(placeID)_\(index).jpg")
            guard let data = try? Data(contentsOf: fileURL),
                  let image = UIImage(data: data) else { break }
            images.append(image)
        }
        return images.isEmpty ? nil : images
    }

    /// Reset the session token (called after place selection)
    private func resetSession() {
        sessionToken = nil
    }
}

// MARK: - Cache Entry

/// NSCache requires reference-type values, so we wrap [UIImage] in a class
private final class PhotoCacheEntry {
    let images: [UIImage]
    init(_ images: [UIImage]) { self.images = images }
}

