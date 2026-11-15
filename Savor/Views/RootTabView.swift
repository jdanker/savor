//
//  RootTabView.swift
//  Savor
//
//  Created by Jahred Danker on 9/29/25.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Spots", systemImage: "fork.knife") {
                HomeListView()
            }
            Tab("Lists", systemImage: "folder") {
                ListsTabView()
            }
            // Deliberately NOT Tab(role: .search): the role forces the system's
            // separated-circle placement with no attached option. A plain tab
            // keeps Search inline with the others, matching current Apple apps.
            Tab("Search", systemImage: "magnifyingglass") {
                SearchTabView()
            }
        }
        // The Apple-apps behavior: the bar shrinks out of the way on scroll-down,
        // reappears on scroll-up
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(SavorTheme.accent)
        // Set once at the root: every system text style below (sheets included,
        // they inherit the environment) renders in SF Rounded. Views keep using
        // semantic styles like .headline, so Dynamic Type still works. UIKit-drawn
        // text (tab bar labels) is not affected.
        .fontDesign(.rounded)
    }
}
#if DEBUG
#Preview {
    RootTabView()
        .environment(AppState.preview)
}
#endif
