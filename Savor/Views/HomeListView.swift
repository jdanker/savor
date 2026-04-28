import SwiftUI

struct HomeListView: View {
    @Environment(AppState.self) private var state

    @State private var selectedRestaurant: Restaurant? = nil

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            ZStack {
                SavorBackground()

                if state.restaurants.isEmpty {
                    emptyState
                } else {
                    List {
                        Section("Saved Spots") {
                            ForEach(state.restaurants) { restaurant in
                                restaurantRow(restaurant)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                            .onDelete(perform: state.remove)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Restaurant", systemImage: "plus") {
                        state.isPresentingAdd = true
                    }
                    .font(.headline)
                    .foregroundStyle(SavorTheme.accent)
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
