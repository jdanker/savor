//
//  ApetiApp.swift
//  Apeti
//
//  Created by Jahred Danker on 9/17/25.
//

import SwiftUI
import GooglePlacesSwift

@main
struct ApetiApp: App {
    @State private var state = AppState(store: RestaurantStore())
    
    init() {
        PlacesClient.provideAPIKey("AIzaSyBjyw427rfICkKh9Iy-jToL81wCWvGe1Y4")
    }
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(state)
                .task { state.load() }
        }
    }
}
