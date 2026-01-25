import SwiftUI

struct HomeListView: View {
    @Environment(AppState.self) private var state

    @State private var selectedRestaurant: Restaurant? = nil

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            Group {
                if state.restaurants.isEmpty {
                    ContentUnavailableView(
                        "No restaurants yet",
                        systemImage: "fork.knife",
                        description: Text("Tap + to add your first place")
                    )
                } else {
                    List {
                        ForEach(state.restaurants) { restaurant in
                            VStack(alignment: .leading) {
                                Text(restaurant.name)
                                    .font(.headline)
                                Text(
                                    "\(restaurant.primaryTypeDisplay)  \(state.levelString(restaurant.priceLevel))"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedRestaurant = restaurant
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
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(restaurant: restaurant)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    HomeListView()
        .environment(AppState.preview)
}
