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
            Tab("List", systemImage: "list.bullet") {
                HomeListView()
            }


        }
    }
}

#Preview {
    RootTabView()
        .environment(AppState.preview)
}
