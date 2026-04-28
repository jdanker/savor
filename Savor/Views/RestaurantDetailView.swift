import SwiftUI

struct RestaurantDetailView: View {
    @Environment(AppState.self) private var state
    let restaurantID: UUID

    private var restaurant: Restaurant {
        state.restaurants.first(where: { $0.id == restaurantID })!
    }

    var body: some View {
        ZStack {
            SavorBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PhotoCarouselView(placeID: restaurant.placeID)
                    heroSection
                    visitStatusTags

                    if let summary = restaurant.editorialSummary, !summary.isEmpty {
                        detailCard(
                            title: "Why it stands out",
                            icon: "fork.knife.circle.fill",
                            body: summary
                        )
                    }

                    if let summary = restaurant.reviewSummary, !summary.isEmpty {
                        detailCard(
                            title: "What people are saying",
                            icon: "sparkles",
                            body: summary
                        )
                    }

                    infoSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if restaurant.needsRefresh {
                await state.refreshPlaceData(for: restaurantID)
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(restaurant.name)
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(SavorTheme.ink)

            metadataRow
        }
    }

    private var visitStatusTags: some View {
        HStack(spacing: 12) {
            tagButton(
                title: "Been",
                icon: "checkmark.circle",
                isSelected: restaurant.visitStatus == .been,
                action: {
                    let newStatus: VisitStatus = restaurant.visitStatus == .been ? .none : .been
                    state.updateVisitStatus(for: restaurant.id, status: newStatus)
                }
            )

            if let url = restaurant.websiteURL {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                        Text("Website")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.5))
                    .foregroundStyle(SavorTheme.ink)
                    .clipShape(Capsule())
                }
            }

            Spacer()
        }
    }

    private func tagButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? SavorTheme.accent : Color.white.opacity(0.55)
            )
            .foregroundStyle(isSelected ? .white : SavorTheme.ink)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var metadataRow: some View {
        HStack(spacing: 8) {
            Text(restaurant.primaryTypeDisplay)
                .foregroundStyle(SavorTheme.mutedInk)
                .lineLimit(1)
                .layoutPriority(-1)

            if !restaurant.priceLevelDisplay.isEmpty {
                Text("•")
                    .foregroundStyle(SavorTheme.mutedInk.opacity(0.5))
                Text(restaurant.priceLevelDisplay)
                    .foregroundStyle(SavorTheme.olive)
            }

            Text("•")
                .foregroundStyle(SavorTheme.mutedInk.opacity(0.5))

            starRatingView(rating: restaurant.rating)
                .fixedSize()
        }
        .font(.subheadline)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Added \(restaurant.addedAt.formatted(date: .abbreviated, time: .omitted))")
            } icon: {
                Image(systemName: "calendar")
            }

            if let refreshed = restaurant.lastRefreshedAt {
                Label {
                    Text("Last refreshed \(refreshed.formatted(date: .abbreviated, time: .omitted))")
                } icon: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .font(.subheadline)
        .foregroundStyle(SavorTheme.mutedInk)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .savorCardStyle()
    }

    private func detailCard(title: String, icon: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(SavorTheme.accent)

            Text(body)
                .font(.body)
                .foregroundStyle(SavorTheme.mutedInk)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .savorCardStyle()
    }

    private func starRatingView(rating: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                let filled = min(max(rating - Double(index - 1), 0), 1)

                ZStack(alignment: .leading) {
                    Image(systemName: "star")
                        .foregroundStyle(SavorTheme.gold.opacity(0.28))

                    GeometryReader { geo in
                        Image(systemName: "star.fill")
                            .foregroundStyle(SavorTheme.gold)
                            .frame(width: geo.size.width * filled, alignment: .leading)
                            .clipped()
                    }
                }
                .font(.subheadline)
                .frame(width: 14, height: 14)
            }

            Text("\(rating, specifier: "%.1f")")
                .font(.subheadline)
                .foregroundStyle(SavorTheme.mutedInk)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        RestaurantDetailView(restaurantID: Restaurant.previewData.first!.id)
            .environment(AppState.preview)
    }
}
#endif
