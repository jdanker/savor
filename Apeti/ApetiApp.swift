//
//  ApetiApp.swift
//  Apeti
//
//  Created by Jahred Danker on 9/17/25.
//

import SwiftUI

@main
struct ApetiApp: App {
    @State private var state = AppState(store: RestaurantStore())
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(state)
                .task { state.load() }
        }
    }
}
