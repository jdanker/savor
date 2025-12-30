//
//  Restaurant.swift
//  Apeti
//
//  Created by Jahred Danker on 9/20/25.
//

import Foundation
import SwiftUI

struct Restaurant: Hashable, Codable, Identifiable {
    let id: UUID

    // Google identity + display
    let placeID: String
    var name: String
    var rating: Double
    var types: [String]
    var priceLevel: Int?
    
    // Metadata
    var addedAt: Date
    
    init (
        id: UUID = UUID(),
        placeID: String,
        name: String,
        rating: Double,
        types: [String],
        addedAt: Date = Date(),
        priceLevel: Int?
    ) {
        self.id = id
        self.placeID = placeID
        self.name = name
        self.rating = rating
        self.types = types
        self.addedAt = addedAt
        self.priceLevel = priceLevel
    }
}

#if DEBUG
extension Restaurant {
    static var previewData: [Restaurant] {
        [
            Restaurant(
                placeID: "preview.cafe-flora",
                name: "Cafe Flora",
                rating: 4.6,
                types: ["cafe", "restaurant"],
                priceLevel: 2
            ),
            Restaurant(
                placeID: "preview.sushi-garden",
                name: "Sushi Garden",
                rating: 4.2,
                types: ["restaurant", "japanese_restaurant"],
                priceLevel: 3
            ),
            Restaurant(
                placeID: "preview.ramen-house",
                name: "Ramen House",
                rating: 4.4,
                types: ["restaurant", "ramen_restaurant"],
                priceLevel: nil
            )
        ]
    }
}
#endif
