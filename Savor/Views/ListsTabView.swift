//
//  ListsTabView.swift
//  Savor
//

import SwiftUI

/// The Lists tab: overview of every list (user-made and Smart Sort), with create/
/// rename/delete and the Smart Sort trigger. A two-column split view, the same
/// shape as Spots and Search: the sidebar holds its own NavigationStack (lists →
/// push ListDetailView), and the detail column shows the selected restaurant.
/// At compact width it collapses to that stack, and restaurant detail falls back
/// to a sheet.
/// Navigation carries the list *ID*, not the list value — the pushed view resolves
/// it live from AppState so renames and membership edits show up immediately.
///
/// Why not three columns (lists | list | restaurant): tried on the Duo simulator.
/// The inner display (~950pt) can't fit three, so the system hid the lists column
/// even with `columnVisibility = .all`, leaving "Pick a List" with no lists visible.
struct ListsTabView: View {
    @Environment(AppState.self) private var state

    @State private var isPresentingNewList = false
    @State private var newListName = ""
    @State private var renamingList: RestaurantList? = nil
    @State private var renameDraft = ""

    /// The sidebar stack's path (list IDs). Observed so that leaving or
    /// switching lists clears a restaurant that belonged to the old one.
    @State private var listPath: [UUID] = []
    @State private var selectedRestaurant: Restaurant? = nil

    var body: some View {
        NavigationSplitView(preferredCompactColumn: .constant(.sidebar)) {
            NavigationStack(path: $listPath) {
                ZStack {
                    SavorBackground()

                    if state.lists.isEmpty {
                        emptyState
                    } else {
                        List {
                            Section("Your Lists") {
                                ForEach(state.lists) { list in
                                    NavigationLink(value: list.id) {
                                        listRow(list)
                                    }
                                    .contextMenu {
                                        Button("Rename", systemImage: "pencil") {
                                            renameDraft = list.name
                                            renamingList = list
                                        }
                                        Button("Delete", systemImage: "trash", role: .destructive) {
                                            state.deleteList(id: list.id)
                                        }
                                    }
                                    // The only grouped system List in the app. Left to the
                                    // default, its rows went system-dark in dark mode under
                                    // SavorTheme.ink text. Themed fill keeps rows and text
                                    // on the same palette in both appearances.
                                    .listRowBackground(SavorTheme.cardFill)
                                }
                                .onDelete { offsets in
                                    let ids = offsets.map { state.lists[$0].id }
                                    for id in ids { state.deleteList(id: id) }
                                }
                            }
                            .textCase(nil)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
                .navigationTitle("Lists")
                .navigationDestination(for: UUID.self) { listID in
                    ListDetailView(listID: listID, selectedRestaurant: $selectedRestaurant)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Smart Sort", systemImage: "wand.and.stars") {
                            state.runSmartSort()
                        }
                        .foregroundStyle(SavorTheme.accent)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("New List", systemImage: "plus") {
                            newListName = ""
                            isPresentingNewList = true
                        }
                        .foregroundStyle(SavorTheme.accent)
                    }
                }
                .alert("New List", isPresented: $isPresentingNewList) {
                    TextField("Name", text: $newListName)
                    Button("Create") { state.createList(name: newListName) }
                    Button("Cancel", role: .cancel) {}
                }
                .alert("Rename List", isPresented: Binding(
                    get: { renamingList != nil },
                    set: { if !$0 { renamingList = nil } }
                )) {
                    TextField("Name", text: $renameDraft)
                    Button("Save") {
                        if let list = renamingList {
                            state.renameList(id: list.id, to: renameDraft)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .savorSidebarColumnWidth()
        } detail: {
            RestaurantDetailColumn(selection: selectedRestaurant)
        }
        .compactRestaurantSheet(selection: $selectedRestaurant)
        .onChange(of: listPath) {
            // A restaurant from the previous list shouldn't linger beside another
            // list (or beside the overview after popping back)
            selectedRestaurant = nil
        }
    }

    private func listRow(_ list: RestaurantList) -> some View {
        HStack(spacing: 12) {
            Image(systemName: list.iconName)
                .foregroundStyle(SavorTheme.accent)
                .frame(width: 28)

            Text(list.name)
                .font(.body.weight(.medium))
                .foregroundStyle(SavorTheme.ink)

            Spacer()

            Text("\(list.restaurantIDs.count)")
                .font(.subheadline)
                .foregroundStyle(SavorTheme.mutedInk)
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Lists Yet", systemImage: "folder")
        } description: {
            Text("Create a list, or let Smart Sort file your saved spots into Coffee, Breakfast, Lunch, Dinner, and Takeout.")
        } actions: {
            Button("Smart Sort", systemImage: "wand.and.stars") {
                state.runSmartSort()
            }
            .buttonStyle(.borderedProminent)
            .tint(SavorTheme.accent)

            Button("New List") {
                newListName = ""
                isPresentingNewList = true
            }
        }
    }
}

#if DEBUG
#Preview {
    ListsTabView()
        .environment(AppState.preview)
}
#endif
