import SwiftUI

struct PhotoCarouselView: View {
    let placeID: String

    @State private var images: [UIImage] = []
    @State private var isLoading = false

    // PlacesService is @MainActor so we access it here directly
    private let placesService = PlacesService()

    // Skip API calls for preview/fake placeIDs
    private var isRealPlace: Bool {
        placeID.hasPrefix("ChIJ") || placeID.hasPrefix("Eh")
    }

    var body: some View {
        Group {
            if isLoading {
                placeholder
            } else if !images.isEmpty {
                carousel
            }
        }
        .task {
            guard isRealPlace else { return }
            isLoading = true
            images = await placesService.fetchPhotos(placeID: placeID)
            isLoading = false
        }
    }

    // MARK: - Carousel

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 280, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .scrollTargetBehavior(.viewAligned)
    }

    // MARK: - Placeholder

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.quaternary)
            .frame(height: 200)
            .overlay {
                ProgressView()
            }
    }
}
