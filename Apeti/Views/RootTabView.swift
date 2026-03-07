//
//  RootTabView.swift
//  Apeti
//
//  Created by Jahred Danker on 9/29/25.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("List", systemImage: "list.bullet") {
                HomeListView()
            }

            Tab("Discover", systemImage: "sparkles") {
                DiscoverView()
            }
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppState.preview)
}
