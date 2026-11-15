import SwiftUI

struct PhotoCarouselView: View {
    let placeID: String

    private static let maxPhotoWidth: CGFloat = 420

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
                    // Sized from the scroll view's width, not a fixed 280×200: the
                    // detail column on iPhone Duo's inner display is much wider than
                    // a phone sheet. 80% of the width leaves the next photo peeking
                    // in (the scroll affordance). The cap stops one photo from
                    // filling a very wide column. Fixed 7:5 tile, and the photo
                    // fills it in an overlay, so odd source ratios crop instead of
                    // stretching the layout.
                    Color.clear
                        .aspectRatio(7.0 / 5.0, contentMode: .fit)
                        .containerRelativeFrame(.horizontal) { length, _ in
                            min(length * 0.8, Self.maxPhotoWidth)
                        }
                        .overlay {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(SavorTheme.cardStroke, lineWidth: 1)
                        )
                }
            }
            // .viewAligned snaps only to children of a scrollTargetLayout. Without
            // this, the existing snap behavior was silently a no-op.
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(SavorTheme.chipFill)
            .frame(height: 200)
            .overlay {
                ProgressView()
                    .tint(SavorTheme.accent)
            }
    }
}
