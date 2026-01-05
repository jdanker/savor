import SwiftUI

struct HomeListView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            Group {
                if state.restaurants.isEmpty {
                    ContentUnavailableView("No restaurants yet",
                        systemImage: "fork.knife",
                        description: Text("Tap + to add your first place"))
                } else {
                    List{
                        ForEach(state.restaurants) { restaurant in
                            VStack(alignment: .leading) {
                                Text(restaurant.name)
                                    .font(.headline)
                                Text("\(restaurant.types.first ?? "restaurant") • \(state.levelString(restaurant.priceLevel))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: state.remove)
                    }
                }
            }
            .navigationTitle("Apeti")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        state.isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $state.isPresentingAdd) {
            AddRestaurantView()
        }
    }
}

#Preview {
    HomeListView()
        .environment(AppState.preview)
}
