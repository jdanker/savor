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

        ZStack(alignment: .bottom) {
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
            
            HStack {
                Spacer()
                
                Button {
                    state.isPresentingAdd = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .fontWeight(.medium)
                }
                .buttonStyle(.glass)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
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
