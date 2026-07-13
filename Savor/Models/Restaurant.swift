//
//  Restaurant.swift
//  Savor
//
//  Created by Jahred Danker on 9/20/25.
//

import CoreLocation
import Foundation
import SwiftUI

enum VisitStatus: String, Codable {
    case none
    case been

    var label: String {
        switch self {
        case .none:
            return "None"
        case .been:
            return "Been"
        }
    }
}

struct Restaurant: Hashable, Codable, Identifiable {
    let id: UUID

    // Google identity + display
    let placeID: String
    var name: String
    var rating: Double
    var types: [String]
    var priceLevel: Int?
    var editorialSummary: String?

    // Stored as raw Doubles (not CLLocationCoordinate2D) to keep the model Codable without
    // conditional conformances. Optional so pre-1.2 saves decode cleanly — backfilled lazily
    // the first time distance sort is used.
    var latitude: Double?
    var longitude: Double?

    // Enriched data — populated lazily via refreshPlaceData, not on initial add
    var websiteURL: URL?
    var reviewSummary: String?
    var lastRefreshedAt: Date?

    // Metadata
    var addedAt: Date
    var visitStatus: VisitStatus

    init(
        id: UUID = UUID(),
        placeID: String,
        name: String,
        rating: Double,
        types: [String],
        addedAt: Date = Date(),
        priceLevel: Int?,
        editorialSummary: String?,
        latitude: Double? = nil,
        longitude: Double? = nil,
        websiteURL: URL? = nil,
        reviewSummary: String? = nil,
        lastRefreshedAt: Date? = nil,
        visitStatus: VisitStatus = .none
    ) {
        self.id = id
        self.placeID = placeID
        self.name = name
        self.rating = rating
        self.types = types
        self.addedAt = addedAt
        self.priceLevel = priceLevel
        self.editorialSummary = editorialSummary
        self.latitude = latitude
        self.longitude = longitude
        self.websiteURL = websiteURL
        self.reviewSummary = reviewSummary
        self.lastRefreshedAt = lastRefreshedAt
        self.visitStatus = visitStatus
    }
}

extension Restaurant {
    /// Meters from the given location, or nil if this restaurant has no stored coordinates
    /// (saved before v1.2 and not yet backfilled).
    func distance(from location: CLLocation) -> CLLocationDistance? {
        guard let latitude, let longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude).distance(from: location)
    }

    /// True if enriched data (website, review summary) has never been fetched or is older than 30 days
    var needsRefresh: Bool {
        guard let refreshed = lastRefreshedAt else { return true }
        return refreshed < Date.now.addingTimeInterval(-30 * 24 * 3600)
    }
}

// helper to properly format restaurant types to be more human readable
extension Restaurant {
    private static func typePriority(_ type: String) -> Int {
        switch type {
        case _ where ["establishment", "point_of_interest"].contains(type):
            return 0

        case _ where type.hasSuffix("_restaurant") && type != "restaurant":
            return 100

        case _ where type.hasSuffix("_shop"):
            return 100

        case _ where type.hasSuffix("_cafe") && type != "cafe":
            return 100

        case "bar_and_grill", "steak_house", "ice_cream_shop", "tea_house",
            "wine_bar":
            return 100

        case "cafe", "bakery", "bar", "pub", "diner", "cafeteria", "food_court":
            return 50

        case "restaurant", "meal_delivery", "meal_takeaway":
            return 25

        default:
            return 75
        }

    }

    var primaryTypeDisplay: String {
        guard !types.isEmpty else { return "Restaurant" }
        let sortedTypes = types.sorted {
            Self.typePriority($0) > Self.typePriority($1)
        }

        return Restaurant.formatPlaceType(sortedTypes.first!)
    }

    static func formatPlaceType(_ rawType: String) -> String {
        let withoutSuffix =
            rawType
            .replacingOccurrences(of: "_restaurant", with: "")
        // handle edge case if type = restaurant
        guard !withoutSuffix.isEmpty else { return "Restaurant" }

        return
            withoutSuffix
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    /// Formats price level (1-4) as dollar signs, nil/invalid returns empty string
    var priceLevelDisplay: String {
        guard let level = priceLevel, (1...4).contains(level) else { return "" }
        return String(repeating: "$", count: level)
    }

    var iconName: String {
        let type = primaryTypeDisplay.lowercased()

        if type.contains("sushi") || type.contains("japanese") {
            return "fish.fill"
        }
        if type.contains("cafe") || type.contains("coffee") || type.contains("bakery") {
            return "cup.and.saucer.fill"
        }
        if type.contains("bar") || type.contains("pub") || type.contains("wine") {
            return "wineglass.fill"
        }
        if type.contains("ice cream") || type.contains("dessert") {
            return "birthday.cake.fill"
        }
        return "fork.knife"
    }
}

#if DEBUG
    extension Restaurant {
        static let previewData: [Restaurant] =
            [
                Restaurant(
                    placeID: "preview.sushi-garden",
                    name: "Sushi Garden",
                    rating: 4.2,
                    types: ["restaurant", "japanese_restaurant"],
                    priceLevel: 3,
                    editorialSummary: "Fresh omakase and creative rolls in a minimalist setting.",
                    latitude: 47.6205,
                    longitude: -122.3493,
                    websiteURL: URL(string: "https://jdanker.com"),
                    reviewSummary: "Guests rave about the melt-in-your-mouth tuna and the chef's creative seasonal rolls. The minimalist space keeps the focus on the fish.",
                    lastRefreshedAt: Date()
                ),
                Restaurant(
                    placeID: "preview.cafe-flora",
                    name: "Cafe Flora",
                    rating: 4.6,
                    types: ["cafe", "restaurant"],
                    priceLevel: 2,
                    editorialSummary: "A beloved neighborhood cafe known for its house-roasted coffee and seasonal brunch menu. The sun-drenched patio fills up fast on weekends, so arrive early or expect a wait.",
                    latitude: 47.6152,
                    longitude: -122.3199,
                    websiteURL: URL(string: "https://jdanker.com"),
                    reviewSummary: "Locals love the single-origin pour-overs and the rotating brunch specials. Expect a wait on weekends — most agree it's worth it.",
                    lastRefreshedAt: Date()
                ),
                Restaurant(
                    placeID: "preview.ramen-house",
                    name: "Ramen House",
                    rating: 4.4,
                    types: ["restaurant", "ramen_restaurant"],
                    priceLevel: nil,
                    editorialSummary: nil,
                    lastRefreshedAt: Date()
                ),
            ]
    }
#endif
