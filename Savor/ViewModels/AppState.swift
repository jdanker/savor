//
//  AppState.swift
//  Savor
//
//  Created by Jahred Danker on 9/20/25.
//
import CoreLocation
import Foundation
import Observation
import SwiftUI
import UIKit

@Observable
@MainActor
final class AppState {
    private(set) var restaurants: [Restaurant] = []

    // MARK: - Manual Form Properties (legacy - can remove when autocomplete is complete)
    var draftPlaceID = ""
    var draftName = ""
    var draftType = ""
    var draftPriceLevel: Int? = nil
    var draftRating = 0.0

    // MARK: - Autocomplete Properties
    var searchQuery = ""
    var isLoadingPlaceDetails = false
    var placesError: String?

    var isPresentingAdd = false

    // MARK: - Distance Sort Properties
    var userLocation: CLLocation?
    var locationDenied = false

    private let store: RestaurantStore
    // Typed as the protocol, not the concrete class: swapping Google-direct for the
    // Go proxy (Phase 1) — or a mock in tests/previews — is a change to this default
    // argument, not to any view or mutation logic
    private let placesService: any PlacesProviding
    private let locationService = LocationService()

    // nil-default rather than `= PlacesService()`: default arguments evaluate in a
    // nonisolated context, so a @MainActor init can't be a default value — but the
    // init body is MainActor-isolated and can construct it fine
    init(store: RestaurantStore, placesService: (any PlacesProviding)? = nil) {
        self.store = store
        self.placesService = placesService ?? PlacesService()
    }
    
    func load() { restaurants = store.load() }
    
    // Mutations
    func commitAdd() {
        guard canSave else { return }
        let placeID = draftPlaceID.trimmingCharacters(
            in: .whitespacesAndNewlines
         )
        let new = Restaurant(
            placeID: draftPlaceID,
            name: draftName,
            rating: draftRating,
            types: [draftType],  // Wrap single type in array
            priceLevel: draftPriceLevel,
            editorialSummary: nil  // Manual entry has no editorial summary
        )
        restaurants.insert(new, at:0)
        store.save(restaurants)
        clearDrafts()
        isPresentingAdd = false
    }
    
    func cancelAdd() {
        clearDrafts()
        searchQuery = ""
        placesError = nil
        isPresentingAdd = false
    }

    // MARK: - Autocomplete Methods

    /// Autocomplete passthrough — views must not construct their own PlacesProviding;
    /// sharing this instance is what keeps the SDK's autocomplete session token (a
    /// billing optimization) alive across keystrokes.
    func searchRestaurants(query: String) async -> Result<[PlaceSuggestion], Error> {
        await placesService.searchRestaurants(query: query)
    }

    /// Called when user selects a restaurant from autocomplete suggestions
    func selectPlace(suggestion: PlaceSuggestion) async {
        isLoadingPlaceDetails = true
        let selectedPlace = await placesService.createRestaurant(from: suggestion)
        switch selectedPlace {
        case .success(let restaurant):
            restaurants.insert(restaurant, at: 0)
            store.save(restaurants)
            searchQuery = ""
            placesError = nil
            isPresentingAdd = false
        case .failure(let error):
            placesError = "Could not load restaurant details, please try again"
            
        }
        
        isLoadingPlaceDetails = false
        
        
    }
    
    /// Lazily fetches enrichable fields (website, review summary) for a restaurant and persists them.
    /// No-op if the restaurant is not found; silently ignores API errors (stale data stays).
    func refreshPlaceData(for restaurantID: UUID) async {
        guard let restaurant = restaurants.first(where: { $0.id == restaurantID }) else { return }
        guard case .success(let updated) = await placesService.refreshRestaurant(restaurant),
              let index = restaurants.firstIndex(where: { $0.id == restaurantID }) else { return }
        restaurants[index] = updated
        store.save(restaurants)
    }

    // MARK: - Distance Sort

    /// Called when the user picks distance sort: grabs a one-shot location fix, then
    /// backfills coordinates for restaurants saved before lat/lng was stored.
    /// Location failure (denied or unavailable) sets locationDenied so the view can
    /// explain why the list isn't sorted, rather than failing silently.
    func prepareDistanceSort() async {
        do {
            userLocation = try await locationService.currentLocation()
            locationDenied = false
        } catch {
            locationDenied = true
            return
        }
        await backfillCoordinates()
    }

    /// One-time migration path for pre-1.2 saves — coordinate-only fetches are the
    /// cheapest Places SKU, and each restaurant only ever needs this once.
    private func backfillCoordinates() async {
        var didUpdate = false
        for index in restaurants.indices where restaurants[index].latitude == nil {
            let placeID = restaurants[index].placeID
            guard let coordinate = await placesService.fetchCoordinate(placeID: placeID) else { continue }
            restaurants[index].latitude = coordinate.latitude
            restaurants[index].longitude = coordinate.longitude
            didUpdate = true
        }
        if didUpdate { store.save(restaurants) }
    }

    /// Photo passthrough for views — same single-service rule as searchRestaurants.
    func photos(for placeID: String) async -> [UIImage] {
        await placesService.fetchPhotos(placeID: placeID)
    }

    func remove(id: UUID) {
        restaurants.removeAll { $0.id == id }
        store.save(restaurants)
    }
    
    func remove(atOffsets offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            restaurants.remove(at: offset)
        }
        store.save(restaurants)
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        restaurants.move(fromOffsets: source, toOffset: destination)
        store.save(restaurants)
    }
    
    func updateVisitStatus(for restaurantID: UUID, status: VisitStatus) {
        guard let index = restaurants.firstIndex(where: { $0.id == restaurantID }) else { return }
        restaurants[index].visitStatus = status
        store.save(restaurants)
    }
    
    // helpers
    var canSave: Bool {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        let trimmedPlaceID = draftPlaceID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPlaceID.isEmpty else { return false }

        return true
    }
    func levelString(_ n: Int?) -> String {
        guard let n, (1...4).contains(n) else { return "" }
        return String(repeating: "$", count: n)
    }
    private func clearDrafts() {
        draftPlaceID = ""
        draftName = ""
        draftType = ""
        draftPriceLevel = nil
        draftRating = 0.0
    }
}

#if DEBUG
extension AppState {
    static var preview: AppState {
        let state = AppState(store: RestaurantStore())
        state.restaurants = Restaurant.previewData
        return state
    }
}
#endif
