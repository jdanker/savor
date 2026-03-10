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
                                    HStack(spacing: 4) {
                                        Text(restaurant.primaryTypeDisplay)
                                        Text("·")
                                        starRating(restaurant.rating)
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if !restaurant.priceLevelDisplay.isEmpty {
                                    Text(restaurant.priceLevelDisplay)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                if restaurant.visitStatus != .none {
                                    statusBadge(for: restaurant.visitStatus)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedRestaurant = restaurant
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    let newStatus: VisitStatus = restaurant.visitStatus == .been ? .none : .been
                                    state.updateVisitStatus(for: restaurant.id, status: newStatus)
                                } label: {
                                    Label(
                                        restaurant.visitStatus == .been ? "Unmark" : "Been",
                                        systemImage: restaurant.visitStatus == .been ? "arrow.uturn.backward" : "checkmark.circle"
                                    )
                                }
                                .tint(.green)
                            }
                        }
                        .onDelete(perform: state.remove)
                        .onMove(perform: state.move)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Savor")
                        .font(.largeTitle.weight(.bold))
                        .fontDesign(.serif)
                }
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
            RestaurantDetailView(restaurantID: restaurant.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Helper Views
    private func starRating(_ rating: Double) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: rating >= Double(i) - 0.25 ? "star.fill"
                     : rating >= Double(i) - 0.75 ? "star.leadinghalf.filled"
                     : "star")
            }
        }
        .font(.caption2)
    }

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
