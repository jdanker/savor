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
    // Core properties
    var name: String
    var type: String
    var priceLevel: Int
    
    // Metadata
    var addedAt: Date
    
    init (
        id: UUID = UUID(),
        name: String,
        type: String,
        priceLevel: Int
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.priceLevel = priceLevel
        self.addedAt = Date()
    }
}
