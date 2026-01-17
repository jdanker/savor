import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing:24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(restaurant.name)
                        .font(.title)
                    Text(restaurant.primaryTypeDisplay)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                starRatingView(rating: restaurant.rating)
                
                // TODO: update this to use the helper function in appstate
                Text("\(restaurant.priceLevel ?? 0)")
                
            }
            .padding()
            
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        
    }

    // MARK: - Helper Views
    private func starRatingView(rating: Double) -> some View {
        HStack(spacing: 4) {
            // TODO: Use ForEach to create 5 stars
            // Syntax: ForEach(range, id: \.self) { index in /* star view */ }
            // Range should be 1...5 (numbers 1 through 5)
            // TODO: Add ForEach(1...5, id: \.self) { index in } here ⬇️

                // TODO: Inside ForEach, add an Image with systemName "star.fill"
                // Syntax: Image(systemName: "name")
                // TODO: Add the star image here ⬇️

                // TODO: Add .foregroundStyle modifier to the star
                // Logic: If the current star index <= rating, show orange (.orange)
                //        Otherwise, show gray (.gray.opacity(0.3))
                // Syntax for conditional: index <= Int(rating) ? .orange : .gray.opacity(0.3)
                // Why Int(rating)? Converts 4.5 to 4, so 4 stars are filled
                // TODO: Add .foregroundStyle with conditional here ⬇️

                // TODO: Add .font(.subheadline) to the star for sizing

            // TODO: Close ForEach

            // TODO: After the ForEach, add a Text showing the numeric rating
            // Syntax: Text("\(rating, specifier: "%.1f")")
            // The specifier formats it to 1 decimal place (e.g., "4.5")
            // TODO: Add rating Text here ⬇️

            // TODO: Add .font(.subheadline) and .foregroundStyle(.secondary) to the Text
        }
    }
}

// MARK: - Preview

#Preview {
    // TODO: Create a preview using the preview data from Restaurant
    // Syntax: ViewName(parameter: value)
    // Use Restaurant.previewData.first! to get a sample restaurant
    // Wrap it in NavigationStack since the view uses navigation modifiers
    // TODO: Add preview here ⬇️

}
