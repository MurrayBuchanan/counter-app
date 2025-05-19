import SwiftUI

struct SymbolGridCollectionAddView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var iconName: String? = "folder"
    @State private var didConfirm = false
    var onAdd: (String, String?) -> Void

    var body: some View {
        SymbolGridView(selectedSymbolName: $iconName, name: $name, didConfirm: $didConfirm)
            .onChange(of: didConfirm) { newValue in
                if newValue {
                    onAdd(name, iconName)
                    dismiss()
                }
            }
    }
} 
