//
//  RootTabView.swift
//  Apeti
//
//  Created by Jahred Danker on 9/29/25.
//

import SwiftUI

struct RootTabView: View {
    @Environment(AppState.self) private var state
    enum Tab { case home, discover }
    @State private var selection: Tab = .home

    var body: some View {
        @Bindable var state = state

        TabView(selection: $selection) {
            HomeListView()
                .tag(Tab.home)
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
            DiscoverView()
                .tag(Tab.discover)
                .tabItem {
                    Label("Discover", systemImage: "sparkles")
                }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                state.isPresentingAdd = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .fontWeight(.medium)
            }
            .buttonStyle(.plain)
            .padding(12)
            .glassEffect(.regular.interactive())
            .clipShape(Circle())
            .padding(.trailing, 20)
            .padding(.bottom, 8)
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
