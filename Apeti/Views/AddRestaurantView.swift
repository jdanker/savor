//
//  AddRestaurantView.swift
//  Apeti
//
//  Created by Jahred Danker on 9/20/25.
//

import SwiftUI

struct AddRestaurantView: View {
    @Environment(AppState.self) private var state
    
    // 1) Enum describing each focusable field
    private enum Field: Hashable {
        case name
        case type
    }
    
    @FocusState private var focusedField: Field?

    var body: some View {
        @Bindable var state = state

        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $state.draftName)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next) // 4) Show "Next" on keyboard
                    TextField("Type", text: $state.draftType)
                        .focused($focusedField, equals: .type)
                        .submitLabel(.done) // 4) Show "Done" on keyboard

                    Picker("Price", selection: $state.draftPriceLevel) {
                        Text("Select").tag(Int?.none)
                        ForEach(1...4, id: \.self) { value in
                            Text(state.levelString(value)).tag(Int?.some(value))
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            // 5) Move to next field when Return is pressed
            .onSubmit {
                switch focusedField {
                case .name:
                    focusedField = .type            // Advance to Type
                case .type:
                    focusedField = nil              // Option A: dismiss keyboard
                    // Option B: immediately save if you want:
                    // if state.canSave { state.commitAdd() }
                default:
                    break
                }
            }
            .onAppear { focusedField = .name }
            .navigationTitle("New Spot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { state.cancelAdd() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { state.commitAdd() }
                        .disabled(!state.canSave)
                }
            }
        }
    }
}


#Preview {
    AddRestaurantView()
        .environment(AppState.preview)
}
