import SwiftUI

struct AddRestaurantView: View {
    @Environment(AppState.self) private var state

    @State private var suggestions: [PlaceSuggestion] = []
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFieldFocused: Bool

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
            ZStack {
                SavorBackground()

                VStack(spacing: 0) {
                    searchBar

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
            }
            .navigationTitle("Add Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { state.cancelAdd() }
                        .foregroundStyle(SavorTheme.accent)
                }
            }
            .onAppear {
                isSearchFieldFocused = true
            }
            .onChange(of: state.searchQuery) { _, newValue in
                searchTask?.cancel()

                guard !newValue.isEmpty else {
                    suggestions = []
                    return
                }

                searchTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }

                    // Search through AppState's shared service — constructing a fresh
                    // PlacesService here would mint a new autocomplete session token
                    // per keystroke, billing every keypress as a separate session
                    let result = await state.searchRestaurants(query: newValue)

                    switch result {
                    case .success(let results):
                        suggestions = results
                    case .failure:
                        suggestions = []
                    }
                }
            }
        }
        .environment(\.colorScheme, .light)
    }

    private var searchBar: some View {
        @Bindable var state = state

        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SavorTheme.accent)

            TextField("Search for a restaurant...", text: $state.searchQuery)
                .autocorrectionDisabled()
                .focused($isSearchFieldFocused)
                .foregroundStyle(SavorTheme.ink)

            if !state.searchQuery.isEmpty {
                Button {
                    state.searchQuery = ""
                    suggestions = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(SavorTheme.mutedInk)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var idlePrompt: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(SavorTheme.accent)
                    .frame(width: 86, height: 86)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Search for a restaurant to add")
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(SavorTheme.ink)

            Text("Pull in a real place, then keep it on your shortlist for the next dinner plan.")
                .font(.subheadline)
                .foregroundStyle(SavorTheme.mutedInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(SavorTheme.accent)
            Text("Loading restaurant details...")
                .font(.caption)
                .foregroundStyle(SavorTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(SavorTheme.rose)
            Text(state.placesError ?? "Something went wrong")
                .font(.subheadline)
                .foregroundStyle(SavorTheme.mutedInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(SavorTheme.accent)

            Text("No restaurants found")
                .font(.headline)
                .foregroundStyle(SavorTheme.ink)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(SavorTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var suggestionsList: some View {
        List {
            Section("Matches") {
                ForEach(suggestions, id: \.placeID) { suggestion in
                    Button {
                        Task { @MainActor in
                            await state.selectPlace(suggestion: suggestion)
                            suggestions.removeAll()
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(SavorTheme.accentSoft)

                                Image(systemName: "fork.knife")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 46, height: 46)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.primaryText)
                                    .font(.headline)
                                    .foregroundStyle(SavorTheme.ink)
                                Text(suggestion.fullText)
                                    .font(.caption)
                                    .foregroundStyle(SavorTheme.mutedInk)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(SavorTheme.accent)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .savorCardStyle()
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .textCase(nil)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#if DEBUG
#Preview {
    AddRestaurantView()
        .environment(AppState.preview)
}
#endif
