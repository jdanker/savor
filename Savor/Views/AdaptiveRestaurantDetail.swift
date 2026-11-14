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

    /// What the sheet is showing. Deliberately separate state, not a computed
    /// binding over `selection`. Unfolding must close the sheet WITHOUT clearing
    /// the selection, and the obvious approach (a binding whose setter ignores
    /// nil after unfolding) failed on the Duo simulator. SwiftUI wrote the
    /// dismissal nil through the binding captured while still compact, which
    /// lost the selection. Owning the sheet's state means only our sync code
    /// and a real user dismissal ever change it.
    @State private var presented: Restaurant?

    /// `nil` (size class not yet known) counts as compact.
    private var isCompact: Bool { horizontalSizeClass != .regular }

    func body(content: Content) -> some View {
        content
            .sheet(item: $presented) { restaurant in
                RestaurantDetailView(restaurantID: restaurant.id)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            // A row tap at compact width presents. Folding closed re-presents
            // whatever the detail column was showing; unfolding dismisses the
            // sheet, and the selection stays for the column.
            .onChange(of: selection?.id, initial: true) { syncPresentation() }
            .onChange(of: horizontalSizeClass) { syncPresentation() }
            .onChange(of: presented?.id) { _, presentedID in
                // The sheet emptied while compact: the user swiped it away, so
                // the selection really is cleared. (While regular, it was our
                // own unfold dismissal, and the selection must survive.)
                if presentedID == nil, isCompact {
                    selection = nil
                }
            }
    }

    private func syncPresentation() {
        presented = isCompact ? selection : nil
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
