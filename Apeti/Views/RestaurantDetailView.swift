import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Hero Section
                heroSection

                // MARK: - Editorial Summary
                if let summary = restaurant.editorialSummary, !summary.isEmpty {
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // MARK: - Info Section
                infoSection
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(restaurant.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            metadataRow
        }
    }

    // MARK: - Metadata Row
    private var metadataRow: some View {
        HStack(spacing: 8) {
            Text(restaurant.primaryTypeDisplay)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .layoutPriority(-1)  // yields space to other elements first

            if !restaurant.priceLevelDisplay.isEmpty {
                Text("•")
                    .foregroundStyle(.tertiary)
                Text(restaurant.priceLevelDisplay)
                    .foregroundStyle(.green)
            }

            Text("•")
                .foregroundStyle(.tertiary)

            starRatingView(rating: restaurant.rating)
                .fixedSize()  // prevents compression of stars + rating
        }
        .font(.subheadline)
    }

    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Added \(restaurant.addedAt.formatted(date: .abbreviated, time: .omitted))")
            } icon: {
                Image(systemName: "calendar")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helper Views
    private func starRatingView(rating: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                let filled = min(max(rating - Double(index - 1), 0), 1)

                ZStack(alignment: .leading) {
                    Image(systemName: "star")
                        .foregroundStyle(.gray.opacity(0.3))

                    GeometryReader { geo in
                        Image(systemName: "star.fill")
                            .foregroundStyle(.orange)
                            .frame(width: geo.size.width * filled, alignment: .leading)
                            .clipped()
                    }
                }
                .font(.subheadline)
                .frame(width: 14, height: 14)
            }

            Text("\(rating, specifier: "%.1f")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RestaurantDetailView(restaurant: Restaurant.previewData.first!)
    }
}
