//
//  AddRestaurantView.swift
//  Savor
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
    @FocusState private var isSearchFieldFocused: Bool

    /// Tracks which content state we're in for animations
    private enum ViewState: Equatable {
        case idle, loading, error, noResults, results
    }

    private var viewState: ViewState {
        if state.isLoadingPlaceDetails { return .loading }
        if state.placesError != nil { return .error }
        if suggestions.isEmpty && !state.searchQuery.isEmpty { return .noResults }
        if !suggestions.isEmpty { return .results }
        return .idle
    }

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                // Animated content transitions between states
                Group {
                    switch viewState {
                    case .idle:
                        idlePrompt
                    case .loading:
                        loadingState
                    case .error:
                        errorState
                    case .noResults:
                        noResultsState
                    case .results:
                        suggestionsList
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewState)
            }
            .navigationTitle("Add Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { state.cancelAdd() }
                }
            }
            .onAppear {
                isSearchFieldFocused = true
            }
            .onChange(of: state.searchQuery) { oldValue, newValue in
                searchTask?.cancel()

                guard !newValue.isEmpty else {
                    suggestions = []
                    return
                }

                searchTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
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

    // MARK: - Search Bar

    private var searchBar: some View {
        @Bindable var state = state

        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search for a restaurant...", text: $state.searchQuery)
                .autocorrectionDisabled()
                .focused($isSearchFieldFocused)

            if !state.searchQuery.isEmpty {
                Button {
                    state.searchQuery = ""
                    suggestions = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    // MARK: - Idle Prompt

    private var idlePrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            VStack(spacing: 8) {
                Text("Search for a restaurant to add")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading restaurant details...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State

    private var errorState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(state.placesError ?? "Something went wrong")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - No Results

    private var noResultsState: some View {
        ContentUnavailableView(
            "No restaurants found",
            systemImage: "magnifyingglass",
            description: Text("Try a different search term")
        )
    }

    // MARK: - Suggestions List

    private var suggestionsList: some View {
        List(suggestions, id: \.placeID) { suggestion in
            Button {
                Task { @MainActor in
                    await state.selectPlace(suggestion: suggestion)
                    suggestions.removeAll()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.attributedPrimaryText)
                            .font(.headline)
                        Text(suggestion.attributedFullText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
#if DEBUG
#Preview {
    AddRestaurantView()
        .environment(AppState.preview)
}
#endif 
