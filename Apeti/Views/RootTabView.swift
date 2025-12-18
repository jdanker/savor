//
//  RootTabView.swift
//  Apeti
//
//  Created by Jahred Danker on 9/29/25.
//

import SwiftUI

struct RootTabView: View {
    enum Tab { case home, discover }
    @State private var selection: Tab = .home
    
    var body: some View {
        TabView(selection: $selection) {
            HomeListView()
                .tag(Tab.home)
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
            DiscoverView()
                .tag(Tab.discover)
                .tabItem{
                    Label("Discover", systemImage: "sparkles")
                }
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppState.preview)
}
