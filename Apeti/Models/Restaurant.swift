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
    var primaryType: String
    var priceLevel: Int?
    
    // Metadata
    var addedAt: Date
    
    init (
        id: UUID = UUID(),
        placeID: String,
        name: String,
        rating: Double,
        primaryType: String,
        addedAt: Date = Date(),
        priceLevel: Int?
    ) {
        self.id = id
        self.placeID = placeID
        self.name = name
        self.rating = rating
        self.primaryType = primaryType
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
                primaryType: "cafe",
                priceLevel: 2
            ),
            Restaurant(
                placeID: "preview.sushi-garden",
                name: "Sushi Garden",
                rating: 4.2,
                primaryType: "restaurant",
                priceLevel: 3
            ),
            Restaurant(
                placeID: "preview.ramen-house",
                name: "Ramen House",
                rating: 4.4,
                primaryType: "restaurant",
                priceLevel: nil
            )
        ]
    }
}
#endif
