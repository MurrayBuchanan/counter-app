// import SwiftUI
// import SwiftData

// class CounterDropDelegate: DropDelegate {
//     let targetCounter: Counter
//     let modelContext: ModelContext
//     
//     init(targetCounter: Counter, modelContext: ModelContext) {
//         self.targetCounter = targetCounter
//         self.modelContext = modelContext
//     }
//     
//     func performDrop(info: DropInfo) -> Bool {
//         guard let itemProvider = info.itemProviders(for: ["public.text"]).first else { return false }
//         
//         itemProvider.loadDataRepresentation(forTypeIdentifier: "public.text") { data, error in
//             guard let data = data,
//                   let id = String(data: data, encoding: .utf8),
//                   let sourceCounter = DragDropUtils.fetchCounter(from: id, context: self.modelContext) else {
//                 return
//             }
//             // Update order of counters
//             sourceCounter.order = self.targetCounter.order
//         }
//         return true
//     }
//     
//     func dropEntered(info: DropInfo) {
//         // Optionally handle highlighting
//     }
//     
//     func dropExited(info: DropInfo) {
//         // Optionally handle highlighting
//     }
//     
//     func dropUpdated(info: DropInfo) -> DropProposal? {
//         return DropProposal(operation: .move)
//     }
// } 