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
    @FocusState private var isSeachFieldFocused: Bool

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            VStack(spacing: 0) {
                // Search TextField
                TextField("Search for a restaurant...", text: $state.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .autocorrectionDisabled()
                    .focused($isSeachFieldFocused)

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
                            // Handle suggestion selection
                            Task { @MainActor in
                                await state.selectPlace(suggestion: suggestion)
                                // Clear the suggestions array after selection
                                suggestions.removeAll()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.attributedPrimaryText)
                                    .font(.headline)
                                Text(suggestion.attributedFullText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
            .onAppear {
                isSeachFieldFocused = true
            }
            .onChange(of: state.searchQuery) { oldValue, newValue in
                // Cancel the existing searchTask if it exists
                searchTask?.cancel()

                // If newValue is empty, clear suggestions and return early
                guard !newValue.isEmpty else {
                    suggestions = []
                    return
                }

                // Create a new Task to perform debounced async search
                searchTask = Task { @MainActor in
                    // Debounce
                    try? await Task.sleep(for: .milliseconds(300))
                    // If the task was cancelled during the debounce, bail out
                    guard !Task.isCancelled else { return }

                    let placesService = PlacesService()
                    let result = await placesService.searchRestaurants(query: newValue)

                    switch result {
                    case .success(let results):
                        suggestions = results
                    case .failure:
                        suggestions = []
                    }
                }
            }
        }
    }
}

#Preview {
    AddRestaurantView()
        .environment(AppState.preview)
}
