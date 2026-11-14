//
//  ListsTabView.swift
//  Savor
//

import SwiftUI

/// The Lists tab: overview of every list (user-made and Smart Sort), with create/
/// rename/delete and the Smart Sort trigger. A three-column split view:
/// lists → ListDetailView → restaurant detail. At compact width it collapses to
/// a stack (selecting a list pushes ListDetailView) and restaurant detail
/// falls back to a sheet.
/// Selection carries the list *ID*, not the list value — ListDetailView resolves
/// it live from AppState so renames and membership edits show up immediately.
struct ListsTabView: View {
    @Environment(AppState.self) private var state

    @State private var isPresentingNewList = false
    @State private var newListName = ""
    @State private var renamingList: RestaurantList? = nil
    @State private var renameDraft = ""

    // Selection-driven navigation (List(selection:)) replaces the old
    // navigationDestination push: in a split view, the sidebar selection is what
    // fills the content column, and the system turns it into a push when collapsed.
    @State private var selectedListID: UUID? = nil
    @State private var selectedRestaurant: Restaurant? = nil
    // Not a constant like the two-column tabs: collapsed, this tab must move
    // between the sidebar and the content column, and the system updates this
    // binding as it pushes and pops.
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $compactColumn) {
            ZStack {
                SavorBackground()

                if state.lists.isEmpty {
                    emptyState
                } else {
                    List(selection: $selectedListID) {
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
            .savorSidebarColumnWidth()
        } content: {
            if let selectedListID {
                ListDetailView(listID: selectedListID, selectedRestaurant: $selectedRestaurant)
                    // Fresh sort state per list, matching the old one-push-per-list behavior
                    .id(selectedListID)
            } else {
                ZStack {
                    SavorBackground()
                    ContentUnavailableView(
                        "Pick a List",
                        systemImage: "folder",
                        description: Text("Choose a list to see its spots.")
                    )
                }
            }
        } detail: {
            RestaurantDetailColumn(selection: selectedRestaurant)
        }
        .compactRestaurantSheet(selection: $selectedRestaurant)
        .onChange(of: selectedListID) {
            // A restaurant from the previous list shouldn't linger beside the new one
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
