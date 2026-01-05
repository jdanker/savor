//
//  AddRestaurantView.swift
//  Apeti
//
//  Created by Jahred Danker on 9/20/25.
//

import SwiftUI
import GooglePlacesSwift

struct AddRestaurantView: View {
    @Environment(AppState.self) private var state

    // MARK: - Local State
    @State private var suggestions: [AutocompletePlaceSuggestion] = []
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            VStack(spacing: 0) {
                // Search TextField
                TextField("Search for a restaurant...", text: $state.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .autocorrectionDisabled()

                // Content: Suggestions, Loading, or Error
                if state.isLoadingPlaceDetails {
                    // Loading state - show spinner
                    VStack {
                        ProgressView()
                        Text("Loading restaurant details...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if let error = state.placesError {
                    // Error state - show error message
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if suggestions.isEmpty && !state.searchQuery.isEmpty {
                    // Empty state - no results
                    ContentUnavailableView(
                        "No restaurants found",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term")
                    )

                } else {
                    // Suggestions List
                    List(suggestions, id: \.placeID) { suggestion in
                        Button {
                            // TODO(human): Handle suggestion selection
                            // 1. Call Task { await state.selectPlace(suggestion: suggestion) }
                            // 2. Clear the suggestions array after selection
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.attributedPrimaryText?.string ?? "Unknown")
                                    .font(.headline)
                                if let fullText = suggestion.attributedFullText {
                                    Text(fullText.string)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { state.cancelAdd() }
                }
            }
            .onChange(of: state.searchQuery) { oldValue, newValue in
                // TODO(human): Implement debounced search
                // 1. Cancel the existing searchTask if it exists
                // 2. If newValue is empty, clear suggestions and return early
                // 3. Create a new Task and assign it to searchTask
                // 4. Inside the task:
                //    - Sleep for 300ms using: try? await Task.sleep(for: .milliseconds(300))
                //    - Check if task was cancelled: guard !Task.isCancelled else { return }
                //    - Call PlacesService to search (you'll need access to it - see note below)
                //    - Update suggestions array with results
            }
        }
    }
}

#Preview {
    AddRestaurantView()
        .environment(AppState.preview)
}
