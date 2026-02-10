//
//  RootTabView.swift
//  Apeti
//
//  Created by Jahred Danker on 9/29/25.
//

import SwiftUI

struct RootTabView: View {
    @Environment(AppState.self) private var state
    enum TabSelection { case home, discover, search }
    @State private var selection: TabSelection = .home

    var body: some View {
        @Bindable var state = state

        TabView(selection: $selection) {
            Tab("List", systemImage: "list.bullet", value: .home) {
                HomeListView()
            }
            
            Tab("Discover", systemImage: "sparkles", value: .discover) {
                DiscoverView()
            }
            
            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                Color.clear
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            if newValue == .search {
                state.isPresentingAdd = true
                selection = oldValue
            }
        }
        .sheet(isPresented: $state.isPresentingAdd) {
            AddRestaurantView()
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppState.preview)
}
