//
//  AdaptiveRestaurantDetail.swift
//  Savor
//

import SwiftUI

// Restaurant detail, presented by available width rather than by device:
// - Regular width (iPhone Duo open, any wide window): a NavigationSplitView
//   detail column beside the list.
// - Compact width (Duo closed, every other iPhone): the medium/large sheet the
//   app has always used.
//
// Each tab holds ONE `Restaurant?` selection that drives both. Folding is a
// runtime size-class change on Duo, so sharing the selection hands an open
// restaurant from sheet to column (and back) instead of dropping it.
// Decisions are made on `horizontalSizeClass`, never `userInterfaceIdiom` —
// Apple's Duo guidance: any size-class combination can occur on iPhone now.

/// The split view's detail column: the selected restaurant, or a prompt to pick one.
/// Renders nothing at compact width. A collapsed split view would otherwise push
/// this column onto the stack, and compact width uses the sheet instead.
struct RestaurantDetailColumn: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let selection: Restaurant?

    var body: some View {
        if horizontalSizeClass == .regular {
            if let selection {
                RestaurantDetailView(restaurantID: selection.id)
                    // New identity per restaurant: resets scroll position and
                    // restarts the photo-loading task instead of reusing them.
                    .id(selection.id)
            } else {
                ZStack {
                    SavorBackground()
                    ContentUnavailableView(
                        "Pick a Spot",
                        systemImage: "fork.knife",
                        description: Text("Choose a saved restaurant to see its details.")
                    )
                }
            }
        }
    }
}

private struct CompactRestaurantSheet: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var selection: Restaurant?

    func body(content: Content) -> some View {
        content.sheet(item: sheetSelection) { restaurant in
            RestaurantDetailView(restaurantID: restaurant.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    /// The selection, as seen by the sheet: visible only at compact width.
    private var sheetSelection: Binding<Restaurant?> {
        // Captured per render, so the binding SwiftUI holds always matches the
        // size class it was built for. `nil` (not yet known) counts as compact.
        let isCompact = horizontalSizeClass != .regular
        return Binding(
            get: { isCompact ? selection : nil },
            set: { newValue in
                // Unfolding forces the sheet closed, and SwiftUI writes nil back
                // through this setter. Ignore that write so the detail column
                // picks up the same restaurant. A real swipe-to-dismiss happens
                // at compact width and still clears the selection.
                if isCompact || newValue != nil {
                    selection = newValue
                }
            }
        )
    }
}

extension View {
    /// Present `selection` as a detail sheet, at compact width only. Pair with
    /// `RestaurantDetailColumn` in the enclosing split view's detail column.
    func compactRestaurantSheet(selection: Binding<Restaurant?>) -> some View {
        modifier(CompactRestaurantSheet(selection: selection))
    }

    /// Shared sidebar width for the tabs' split views. The default sidebar is
    /// narrower than RestaurantRow was designed for, and on Duo's inner display
    /// there's room to spare.
    func savorSidebarColumnWidth() -> some View {
        navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 460)
    }
}
