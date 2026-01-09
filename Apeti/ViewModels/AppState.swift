//
//  AppState.swift
//  Apeti
//
//  Created by Jahred Danker on 9/20/25.
//
import Foundation
import Observation
import GooglePlacesSwift

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

    private let store: RestaurantStore
    private let placesService = PlacesService()

    init(store: RestaurantStore) {
        self.store = store
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
            priceLevel: draftPriceLevel
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

    /// Called when user selects a restaurant from autocomplete suggestions
    func selectPlace(suggestion: AutocompletePlaceSuggestion) async {
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
