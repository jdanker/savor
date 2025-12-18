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
    
    var draftName = ""
    var draftType = ""
    var draftPriceLevel: Int? = nil
    
    var isPresentingAdd = false
    
    private let store: RestaurantStore
    
    init(store: RestaurantStore) {
        self.store = store
    }
    
    func load() { restaurants = store.load() }
    
    // Mutations
    func commitAdd() {
        guard let priceLevel = draftPriceLevel, canSave else { return }
        let new = Restaurant(
            name: draftName,
            type: draftType,
            priceLevel: priceLevel
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
        guard let priceLevel = draftPriceLevel else { return false }
        return (1...4).contains(priceLevel)
    }
    func levelString(_ n: Int) -> String { String(repeating: "$", count: n) }
    private func clearDrafts() { draftName = ""; draftType = ""; draftPriceLevel = nil }
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
