import SwiftUI

struct PhotoCarouselView: View {
    let placeID: String

    @Environment(AppState.self) private var state

    @State private var images: [UIImage] = []
    @State private var isLoading = false

    private var isPreviewPlace: Bool {
        placeID.hasPrefix("preview.")
    }

    var body: some View {
        VStack {
            if isLoading {
                placeholder
            } else if !images.isEmpty {
                carousel
            }
        }
        .task {
            guard !isPreviewPlace else { return }
            isLoading = true
            images = await state.photos(for: placeID)
            isLoading = false
        }
    }

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 280, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
        .scrollTargetBehavior(.viewAligned)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white.opacity(0.5))
            .frame(height: 200)
            .overlay {
                ProgressView()
                    .tint(SavorTheme.accent)
            }
    }
}
