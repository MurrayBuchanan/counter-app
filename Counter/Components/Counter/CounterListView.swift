import SwiftUI
import SwiftData

struct CounterListView: View {
    let counters: [Counter]
    @Binding var draggedCounter: Counter?
    @Binding var dropTarget: Counter?
    @Binding var dropPosition: AllCountersViewModel.DropPosition
    let context: ModelContext
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(counters.enumerated()), id: \.element.id) { idx, counter in
                counterRow(idx: idx, counter: counter)
            }
        }
    }
    
    @ViewBuilder
    private func counterRow(idx: Int, counter: Counter) -> some View {
        VStack(spacing: 0) {
            // Drop indicator and target before each counter
            if draggedCounter != nil && dropTarget == counter && dropPosition == .before {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 3)
                    .cornerRadius(2)
                    .transition(.opacity)
            }
            // Drop target before each counter
            if draggedCounter != nil {
                Color.clear
                    .frame(height: 0)
                    .onDrop(of: ["public.text"], delegate: MainListDropDelegate(
                        targetCounter: counter,
                        modelContext: context
                    ))
            }
            CounterCardView(counter: counter, isDropTarget: dropTarget == counter, dropPosition: dropTarget == counter ? dropPosition : .none)
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
                .opacity(dropTarget == counter ? 0.5 : 1.0)
                .onDrag {
                    self.draggedCounter = counter
                    return DragDropUtils.createItemProvider(for: counter)
                }
                .onDrop(of: ["public.text"], delegate: CounterDropDelegate(
                    targetCounter: counter,
                    modelContext: context
                ))
            // Drop indicator and target after each counter
            if draggedCounter != nil && dropTarget == counter && dropPosition == .after {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 3)
                    .cornerRadius(2)
                    .transition(.opacity)
            }
            if draggedCounter != nil {
                Color.clear
                    .frame(height: 0)
                    .onDrop(of: ["public.text"], delegate: MainListDropDelegate(
                        targetCounter: counter,
                        modelContext: context
                    ))
            }
        }
    }
}

struct MainListDropDelegate: DropDelegate {
    let targetCounter: Counter
    let modelContext: ModelContext
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: ["public.text"]).first else { return false }
        
        itemProvider.loadDataRepresentation(forTypeIdentifier: "public.text") { data, error in
            guard let data = data,
                  let id = String(data: data, encoding: .utf8),
                  let sourceCounter = DragDropUtils.fetchCounter(from: id, context: modelContext) else {
                return
            }
            
            // Update order of counters
            sourceCounter.order = targetCounter.order
            targetCounter.order += 1
            
          
        }
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // No need to implement this method
    }
    
    func dropExited(info: DropInfo) {
        // No need to implement this method
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

#Preview {
    CounterListView(
        counters: [],
        draggedCounter: .constant(nil),
        dropTarget: .constant(nil),
        dropPosition: .constant(.none),
        context: ModelContext(try! ModelContainer(for: Counter.self))
    )
} 
