//
//  RestaurantStore.swift
//  Savor
//
//  Created by Jahred Danker on 9/20/25.
//

import Foundation

final class RestaurantStore {
    private let fileUrl: URL
    
    init() {
        let dir  = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        fileUrl = dir.appendingPathComponent("restaurants.json")
    }
    func load() -> [Restaurant] {
        do {
            let data = try Data(contentsOf: fileUrl)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Restaurant].self, from: data)
        } catch {
            // File doesn’t exist yet or decode failed
            return []
        }
    }
    
    func save(_ restaurants: [Restaurant]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(restaurants)
            try data.write(to: fileUrl, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }
}
