import SwiftUI
import SwiftData

@Observable
class AllCountersViewModel {
    var showAddSheet = false
    var selectedCounter: Counter?
    var searchText = ""
    
    var draggedCounter: Counter?
    var dropTarget: Counter?
    var dropPosition: DropPosition = .none
    var context: ModelContext
    
    enum DropPosition {
        case none
        case before
        case after
    }
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func handleCounterDrop(_ counter: Counter, info: DropInfo) -> Bool {
        guard let draggedCounter = draggedCounter else { return false }
        
        // Don't do anything if dropping onto itself
        if draggedCounter == counter { return false }
        
        // Reset the states
        self.draggedCounter = nil
        self.dropTarget = nil
        self.dropPosition = .none
        
        return true
    }
    
    func updateDropPosition(_ info: DropInfo) {
        let location = info.location
        let height = 60.0 // Fixed height for items
        
        if location.y < height * 0.3 {
            dropPosition = .before
        } else if location.y > height * 0.7 {
            dropPosition = .after
        } else {
            dropPosition = .none
        }
    }
} 
