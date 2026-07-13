import CoreLocation
import SwiftUI

/// How the saved list is ordered. Sorting is a view-level projection — the persisted
/// array order always means "manual order", so no sort ever calls store.save.
enum SortOption: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case price = "Price"
    case rating = "Rating"
    case distance = "Distance"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .manual: return "hand.draw"
        case .price: return "dollarsign.circle"
        case .rating: return "star"
        case .distance: return "location"
        }
    }
}

struct HomeListView: View {
    @Environment(AppState.self) private var state

    @State private var selectedRestaurant: Restaurant? = nil
    @State private var sortOption: SortOption = .manual

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            ZStack {
                SavorBackground()

                if state.restaurants.isEmpty {
                    emptyState
                } else {
                    List {
                        if sortOption == .distance && state.locationDenied {
                            locationDeniedNotice
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }

                        Section("Saved Spots") {
                            ForEach(sortedRestaurants) { restaurant in
                                restaurantRow(restaurant)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    // Reordering a sorted projection is meaningless (it would
                                    // snap back), so drag-to-reorder only exists in manual order.
                                    // moveDisabled (vs. a conditional onMove handler) also avoids
                                    // an @MainActor function-conversion error under Swift 6.2's
                                    // default-isolation settings.
                                    .moveDisabled(sortOption != .manual)
                            }
                            .onDelete(perform: delete)
                            .onMove(perform: state.move)
                        }
                        .textCase(nil)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Savor")
                            .font(.title.weight(.bold))
                            .fontDesign(.serif)
                            .foregroundStyle(SavorTheme.ink)
                        Text("Your restaurant shortlist")
                            .font(.caption)
                            .foregroundStyle(SavorTheme.mutedInk)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Label(option.rawValue, systemImage: option.icon)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.headline)
                            .foregroundStyle(SavorTheme.accent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Restaurant", systemImage: "plus") {
                        state.isPresentingAdd = true
                    }
                    .font(.headline)
                    .foregroundStyle(SavorTheme.accent)
                }
            }
            .onChange(of: sortOption) { _, newValue in
                // Location fix + coordinate backfill are only needed (and only billed/
                // prompted) once the user actually asks for distance ordering
                if newValue == .distance {
                    Task { await state.prepareDistanceSort() }
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

    // MARK: - Sorting

    /// The list as displayed: a sorted projection over the persisted array.
    /// Manual returns the stored order untouched; the persisted data is never re-sorted.
    private var sortedRestaurants: [Restaurant] {
        switch sortOption {
        case .manual:
            return state.restaurants
        case .price:
            return state.restaurants.sorted(by: isOrderedByPrice)
        case .rating:
            // Best first; unrated restaurants carry 0.0 so they naturally land last
            return state.restaurants.sorted { $0.rating > $1.rating }
        case .distance:
            // Until the location fix arrives (or if denied), show the manual order
            guard let here = state.userLocation else { return state.restaurants }
            return state.restaurants.sorted {
                ($0.distance(from: here) ?? .greatestFiniteMagnitude)
                    < ($1.distance(from: here) ?? .greatestFiniteMagnitude)
            }
        }
    }

    /// Comparator for price sort: cheapest first. nil (no price data from Google) maps
    /// to Int.max so unpriced restaurants sort last — same sentinel approach as the
    /// distance sort. Strict ordering: equal price levels return false.
    private func isOrderedByPrice(_ a: Restaurant, _ b: Restaurant) -> Bool {
        (a.priceLevel ?? Int.max) < (b.priceLevel ?? Int.max)
    }

    /// Swipe-to-delete hands us offsets into the *displayed* (sorted) array, which may
    /// not match the stored array's order — map to stable IDs before mutating.
    private func delete(atOffsets offsets: IndexSet) {
        let ids = offsets.map { sortedRestaurants[$0].id }
        for id in ids {
            state.remove(id: id)
        }
    }

    private var locationDeniedNotice: some View {
        Label("Enable location access in Settings to sort by distance.", systemImage: "location.slash")
            .font(.caption)
            .foregroundStyle(SavorTheme.mutedInk)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func restaurantRow(_ restaurant: Restaurant) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SavorTheme.accentSoft)

                Image(systemName: restaurant.iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(restaurant.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(SavorTheme.ink)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if !restaurant.priceLevelDisplay.isEmpty {
                        Text(restaurant.priceLevelDisplay)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SavorTheme.olive)
                    }
                }

                HStack(spacing: 6) {
                    Text(restaurant.primaryTypeDisplay.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(SavorTheme.mutedInk)

                    Text("•")
                        .foregroundStyle(SavorTheme.mutedInk.opacity(0.5))

                    starRating(restaurant.rating)
                }

                if let summary = restaurant.editorialSummary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(SavorTheme.mutedInk)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if restaurant.visitStatus != .none {
                        statusBadge(for: restaurant.visitStatus)
                    }

                    Text("Added \(restaurant.addedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(SavorTheme.mutedInk.opacity(0.8))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .savorCardStyle()
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
            .tint(SavorTheme.olive)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(SavorTheme.accent)
                    .frame(width: 88, height: 88)

                Image(systemName: "fork.knife")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.white)
            }

            Text("Build your first shortlist")
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(SavorTheme.ink)

            Text("Save restaurants that look promising, then mark the ones that were actually worth the reservation.")
                .font(.subheadline)
                .foregroundStyle(SavorTheme.mutedInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button {
                state.isPresentingAdd = true
            } label: {
                Label("Add a Restaurant", systemImage: "plus")
                    .font(.headline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(SavorTheme.accent, in: Capsule())
                    .foregroundStyle(Color.white)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func starRating(_ rating: Double) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: rating >= Double(i) - 0.25 ? "star.fill"
                     : rating >= Double(i) - 0.75 ? "star.leadinghalf.filled"
                     : "star")
            }
        }
        .font(.caption2)
        .foregroundStyle(SavorTheme.gold)
    }

    @ViewBuilder
    private func statusBadge(for status: VisitStatus) -> some View {
        let (icon, color) = statusIconAndColor(for: status)

        Label(status.label, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.16), in: Capsule())
    }

    private func statusIconAndColor(for status: VisitStatus) -> (String, Color) {
        switch status {
        case .been:
            return ("checkmark.circle.fill", SavorTheme.olive)
        case .none:
            return ("", .clear)
        }
    }
}

#if DEBUG
#Preview {
    HomeListView()
        .environment(AppState.preview)
}
#endif
