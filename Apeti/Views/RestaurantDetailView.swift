import SwiftUI

struct RestaurantDetailView: View {
    // MARK: - Properties
    let restaurant: Restaurant

    // MARK: - Body

    var body: some View {
        // TODO: Wrap everything in a ScrollView
        // Syntax: ScrollView { /* content */ }
        // Why? Content might be longer than screen, needs to scroll
        // TODO: Add ScrollView here ⬇️

            // TODO: Add a VStack with alignment: .leading and spacing: 24
            // Syntax: VStack(alignment: .leading, spacing: 24) { /* content */ }
            // Why .leading? Left-aligns all sections (standard for detail views)
            // TODO: Add VStack here ⬇️

                // Section 1: Header with name and type
                // TODO: Add a VStack for the header (alignment: .leading, spacing: 8)
                // Inside it, add:
                //   - Text(restaurant.name) with font .title
                //   - Text(restaurant.primaryTypeDisplay) with font .headline and foregroundStyle .secondary
                // TODO: Create header VStack here ⬇️


                // Section 2: Star Rating Display
                // TODO: Call the starRatingView helper (we'll create it below)
                // Syntax: functionName(parameter: value)
                // TODO: Add starRatingView(rating: restaurant.rating) here ⬇️


                // Section 3: Price Level
                // TODO: Add a Text showing the price level
                // Use AppState's levelString helper (but we don't have access to it here yet...)
                // For now, just show the raw priceLevel number or skip this section
                // We'll come back to this


            // TODO: Close VStack
            // TODO: Add .padding() modifier to the VStack
            // This adds space around all edges

        // TODO: Close ScrollView
        // TODO: Add .navigationTitle(restaurant.name) to the ScrollView
        // This sets the title in the sheet's top bar
        // TODO: Add .navigationBarTitleDisplayMode(.inline)
        // This keeps the title small (not large style)
    }

    // MARK: - Helper Views

    // This is a helper function that returns a View
    // It creates the star rating display
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
