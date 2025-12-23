//
//  AppState.swift
//  Apeti
//
//  Created by Jahred Danker on 9/20/25.
//
import Foundation
import Observation
@Observable
@MainActor
final class AppState {
    private(set) var restaurants: [Restaurant] = []
    
    var draftPlaceID = ""
    var draftName = ""
    var draftType = ""
    var draftPriceLevel: Int? = nil
    var draftRating = 0.0
    
    var isPresentingAdd = false
    
    private let store: RestaurantStore
    
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
            primaryType: draftType,
            priceLevel: draftPriceLevel

        )
        restaurants.insert(new, at:0)
        store.save(restaurants)
        clearDrafts()
        isPresentingAdd = false
    }
    
    func cancelAdd() {
        clearDrafts()
        isPresentingAdd = false
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
