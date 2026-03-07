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
                            HStack(spacing: 12) {
                                VStack(alignment: .leading) {
                                    Text(restaurant.name)
                                        .font(.headline)
                                    Text(
                                        "\(restaurant.primaryTypeDisplay)  \(state.levelString(restaurant.priceLevel))"
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if restaurant.visitStatus != .none {
                                    statusBadge(for: restaurant.visitStatus)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedRestaurant = restaurant
                            }
                        }
                        .onDelete(perform: state.remove)
                        .onMove(perform: state.move)
                    }
                }
            }
            .navigationTitle("Apeti")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Restaurant", systemImage: "plus") {
                        state.isPresentingAdd = true
                    }
                    .font(.title2)
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
    
    // MARK: - Helper Views
    @ViewBuilder
    private func statusBadge(for status: VisitStatus) -> some View {
        let (icon, color) = statusIconAndColor(for: status)
        
        Image(systemName: icon)
            .font(.caption)
            .foregroundStyle(color)
            .padding(6)
            .background(color.opacity(0.15))
            .clipShape(Circle())
    }
    
    private func statusIconAndColor(for status: VisitStatus) -> (String, Color) {
        switch status {
        case .wantToTry:
            return ("bookmark.fill", .blue)
        case .been:
            return ("checkmark.circle.fill", .green)
        case .none:
            return ("", .clear)
        }
    }
}

#Preview {
    HomeListView()
        .environment(AppState.preview)
}
