import SwiftUI

struct AddCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var collectionName: String = ""
    @State private var iconName: String? = "folder"
    @State private var showingSymbolPicker = false
    @State private var didConfirm = false
    var onAdd: ((String, String?) -> Void)?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        Spacer(minLength: 8)
                        // Large icon preview
                        if let icon = iconName {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 72, height: 72)
                                .foregroundColor(.accentColor)
                                .frame(maxWidth: .infinity)
                        } else {
                            Rectangle().frame(width: 72, height: 72).opacity(0)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                Section(header: Text("Collection Name")) {
                    TextField("Name", text: $collectionName)
                }
                Section(header: Text("Icon")) {
                    Button {
                        showingSymbolPicker = true
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            if let icon = iconName {
                                Image(systemName: icon)
                                    .foregroundColor(.accentColor)
                            } else {
                                Text("None")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd?(collectionName, iconName)
                        dismiss()
                    }
                    .disabled(collectionName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingSymbolPicker) {
                NavigationStack {
                    SymbolGridView(selectedSymbolName: $iconName, name: $collectionName, didConfirm: $didConfirm)
                }
            }
        }
    }
}

#Preview {
    AddCollectionView { name, icon in
        print("Added collection: \(name) with icon: \(icon ?? "none")")
    }
} 
