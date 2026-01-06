//
//  ApetiApp.swift
//  Apeti
//
//  Created by Jahred Danker on 9/17/25.
//

import SwiftUI
import GooglePlaces  // Legacy SDK (required dependency)
import GooglePlacesSwift

@main
struct ApetiApp: App {
    @State private var state = AppState(store: RestaurantStore())

    init() {
        // Read API key from Info.plist (which gets it from Secrets.xcconfig)
        guard let apiKey = Bundle.main.infoDictionary?["GooglePlacesAPIKey"] as? String else {
            fatalError("GooglePlacesAPIKey not found in Info.plist")
        }

        // Initialize both SDKs (new Swift SDK depends on legacy SDK internally)
        GMSPlacesClient.provideAPIKey(apiKey)
        PlacesClient.provideAPIKey(apiKey)
    }
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(state)
                .task { state.load() }
        }
    }
}
