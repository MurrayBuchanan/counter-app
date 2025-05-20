//
//  ContentView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import SwiftData
import AVFoundation

// Minimal working drop delegate for diagnostic purposes
@MainActor
class MyDropDelegate: DropDelegate {
    let id: Int
    init(id: Int) { self.id = id }
    func performDrop(info: DropInfo) -> Bool { true }
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\CounterCollection.order)]) private var collections: [CounterCollection]
    @Query(sort: [SortDescriptor(\Counter.order)]) private var allCounters: [Counter]
    @State private var searchText = ""
    @State private var showAddSheet = false
    @State private var showNewCollectionSheet = false
    @State private var selectedCounter: Counter?
    @State private var dragOverSection: UUID? = nil
    @State private var dragOverIndex: (collection: UUID?, index: Int)? = nil
    @State private var draggingCounterID: UUID? = nil
    @State private var isUnassignedHeaderDropTarget: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack() {
                    unassignedSection
                    ForEach(filteredCollections) { collection in
                        collectionSection(collection)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 12)
            }
            .searchable(text: $searchText)
            .navigationTitle("Counters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button { showNewCollectionSheet = true } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                        Button { showAddSheet = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showAddSheet) {
                NavigationStack {
                    AddCounterView(collections: collections)
                        .environment(\.modelContext, context)
                }
            }
            .sheet(isPresented: $showNewCollectionSheet) {
                NavigationStack {
                    SymbolGridCollectionAddView(onAdd: { name, iconName in
                        let newOrder = (collections.map { $0.order }.max() ?? 0) + 1
                        let collection = CounterCollection(name: name, order: newOrder, iconName: iconName)
                        context.insert(collection)
                    })
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var unassignedSection: some View {
        let counters = allCounters.filter { $0.collection == nil }.sorted(by: { $0.order < $1.order })
        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                title: "Unassigned",
                collection: nil,
                isDropTarget: isUnassignedHeaderDropTarget,
                isTargeted: $isUnassignedHeaderDropTarget,
                onDrop: { providers in
                    handleDrop(to: nil, at: counters.count, providers: providers)
                    return true
                }
            )
            // Drop indicator before first row
            DropIndicator(isActive: dragOverIndex?.collection == nil && dragOverIndex?.index == 0)
                .onDrop(of: ["public.text"], isTargeted: Binding(
                    get: { dragOverIndex?.collection == nil && dragOverIndex?.index == 0 },
                    set: { isTargeted in dragOverIndex = isTargeted ? (nil, 0) : nil }
                ), perform: { providers in
                    handleDrop(to: nil, at: 0, providers: providers)
                    return true
                })
            ForEach(Array(counters.enumerated()), id: \.1.uuid) { idx, counter in
                DraggableCounterRow(
                    counter: counter,
                    collectionID: nil,
                    idx: idx,
                    isDropTarget: dragOverIndex?.collection == nil && dragOverIndex?.index == idx,
                    onDrag: { draggingCounterID = counter.uuid },
                    onDrop: { providers in
                        handleDrop(to: nil, at: idx, providers: providers)
                        return true
                    },
                    dragOverIndex: $dragOverIndex
                )
                .animation(.easeInOut, value: counter.order)
                // Drop indicator after each row
                DropIndicator(isActive: dragOverIndex?.collection == nil && dragOverIndex?.index == idx + 1)
                    .onDrop(of: ["public.text"], isTargeted: Binding(
                        get: { dragOverIndex?.collection == nil && dragOverIndex?.index == idx + 1 },
                        set: { isTargeted in dragOverIndex = isTargeted ? (nil, idx + 1) : nil }
                    ), perform: { providers in
                        handleDrop(to: nil, at: idx + 1, providers: providers)
                        return true
                    })
            }
        }
        .padding(.bottom, 24)
    }
    
    private func collectionSection(_ collection: CounterCollection) -> some View {
        let counters = collection.counters.sorted(by: { $0.order < $1.order })
        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                title: collection.name,
                collection: collection,
                isDropTarget: dragOverSection == collection.uuid,
                isTargeted: Binding(
                    get: { dragOverSection == collection.uuid },
                    set: { isTargeted in dragOverSection = isTargeted ? collection.uuid : nil }
                ),
                onDrop: { providers in
                    handleDrop(to: collection, at: counters.count, providers: providers)
                    return true
                }
            )
            // Drop indicator before first row
            DropIndicator(isActive: dragOverIndex?.collection == collection.uuid && dragOverIndex?.index == 0)
                .onDrop(of: ["public.text"], isTargeted: Binding(
                    get: { dragOverIndex?.collection == collection.uuid && dragOverIndex?.index == 0 },
                    set: { isTargeted in dragOverIndex = isTargeted ? (collection.uuid, 0) : nil }
                ), perform: { providers in
                    handleDrop(to: collection, at: 0, providers: providers)
                    return true
                })
            if collection.isExpanded {
                ForEach(Array(counters.enumerated()), id: \.1.uuid) { idx, counter in
                    DraggableCounterRow(
                        counter: counter,
                        collectionID: collection.uuid,
                        idx: idx,
                        isDropTarget: dragOverIndex?.collection == collection.uuid && dragOverIndex?.index == idx,
                        onDrag: { draggingCounterID = counter.uuid },
                        onDrop: { providers in
                            handleDrop(to: collection, at: idx, providers: providers)
                            return true
                        },
                        dragOverIndex: $dragOverIndex
                    )
                    .animation(.easeInOut, value: counter.order)
                    // Drop indicator after each row
                    DropIndicator(isActive: dragOverIndex?.collection == collection.uuid && dragOverIndex?.index == idx + 1)
                        .onDrop(of: ["public.text"], isTargeted: Binding(
                            get: { dragOverIndex?.collection == collection.uuid && dragOverIndex?.index == idx + 1 },
                            set: { isTargeted in dragOverIndex = isTargeted ? (collection.uuid, idx + 1) : nil }
                        ), perform: { providers in
                            handleDrop(to: collection, at: idx + 1, providers: providers)
                            return true
                        })
                }
            }
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Filtering
    
    private var filteredCollections: [CounterCollection] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return collections
        } else {
            return collections.filter { collection in
                collection.counters.contains(where: { matchesSearch($0) })
            }
        }
    }
    private func matchesSearch(_ counter: Counter) -> Bool {
        searchText.trimmingCharacters(in: .whitespaces).isEmpty || counter.name.localizedCaseInsensitiveContains(searchText)
    }
    
    // MARK: - Move and Drop Logic
    
    private func moveCountersInUnassigned(from source: IndexSet, to destination: Int) {
        withAnimation(.easeInOut) {
            var counters = allCounters.filter { $0.collection == nil }.sorted(by: { $0.order < $1.order })
            counters.move(fromOffsets: source, toOffset: destination)
            for (index, counter) in counters.enumerated() {
                counter.order = index
                counter.collection = nil
            }
        }
    }
    
    private func moveCountersInCollection(_ collection: CounterCollection, from source: IndexSet, to destination: Int) {
        withAnimation(.easeInOut) {
            var counters = collection.counters.sorted(by: { $0.order < $1.order })
            counters.move(fromOffsets: source, toOffset: destination)
            for (index, counter) in counters.enumerated() {
                counter.order = index
                counter.collection = collection
            }
            collection.counters = counters
        }
    }
    
    private func handleDrop(to collection: CounterCollection?, at index: Int, providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { (item, error) in
            var idString: String?
            if let data = item as? Data {
                idString = String(data: data, encoding: .utf8)
            } else if let str = item as? String {
                idString = str
            }
            guard let idString,
                  let counter = DragDropUtils.fetchCounter(from: idString, context: context) else { return }
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    // Remove from old collection if needed
                    if let oldCollection = counter.collection {
                        oldCollection.counters.removeAll { $0 === counter }
                        let oldCounters = oldCollection.counters.sorted(by: { $0.order < $1.order })
                        for (idx, c) in oldCounters.enumerated() { c.order = idx }
                        oldCollection.counters = oldCounters
                    } else {
                        let unassigned = allCounters.filter { $0.collection == nil }.sorted(by: { $0.order < $1.order })
                        let filtered = unassigned.filter { $0 !== counter }
                        for (idx, c) in filtered.enumerated() { c.order = idx }
                    }
                    // Assign to new collection (or nil)
                    counter.collection = collection
                    if let collection = collection {
                        var counters = collection.counters.sorted(by: { $0.order < $1.order })
                        counters.removeAll { $0 === counter }
                        let safeIndex = min(max(index, 0), counters.count)
                        counters.insert(counter, at: safeIndex)
                        for (idx, c) in counters.enumerated() { c.order = idx }
                        collection.counters = counters
                    } else {
                        var unassigned = allCounters.filter { $0.collection == nil && $0 !== counter }.sorted(by: { $0.order < $1.order })
                        let safeIndex = min(max(index, 0), unassigned.count)
                        unassigned.insert(counter, at: safeIndex)
                        for (idx, c) in unassigned.enumerated() { c.order = idx; c.collection = nil }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func sectionHeader(title: String, collection: CounterCollection?, isDropTarget: Bool, isTargeted: Binding<Bool>? = nil, onDrop: (([NSItemProvider]) -> Bool)? = nil) -> some View {
        let header = HStack(spacing: 12) {
            if let collection = collection {
                Image(systemName: collection.iconName ?? "folder")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
            } else {
                Image(systemName: "tray")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
            }
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            if let collection = collection {
                Text("\(collection.counters.count)")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                Button(action: { withAnimation { collection.isExpanded.toggle() } }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(collection.isExpanded ? 90 : 0))
                        .scaleEffect(collection.isExpanded ? 1.1 : 1.0)
                        .opacity(collection.isExpanded ? 1.0 : 0.85)
                }
                .buttonStyle(.plain)
                .frame(width: 24, alignment: .trailing)
                .zIndex(1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDropTarget ? Color(UIColor.quaternaryLabel) : Color(.clear))
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        if let onDrop = onDrop, let isTargeted = isTargeted {
            header.onDrop(of: ["public.text"], isTargeted: isTargeted, perform: { providers in
                let result = onDrop(providers)
                return result
            })
        } else {
            header
        }
    }

    @ViewBuilder
    private func DropIndicator(isActive: Bool) -> some View {
        ZStack {
            // Invisible hit area for easier drop
            Color.clear
                .frame(height: 16)
            // Visible line
            RoundedRectangle(cornerRadius: 2)
                .fill(isActive ? Color(UIColor.quaternaryLabel) : Color.clear)
                .frame(height: 4)
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.18), value: isActive)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - CounterRowView
private struct CounterRowView: View {
    let counter: Counter
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    @State private var isActive = false
    
    private var theme: Theme {
        ThemeManager.shared.theme(for: counter)
    }
    
    private var progress: Double {
        guard let goal = counter.goalValue, goal > 0 else { return 1.0 }
        return min(Double(counter.value) / Double(goal), 1.0)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Filled part
                    theme.gradient
                        .frame(width: geo.size.width * progress)
                    // Unfilled part
                    if progress < 1.0 {
                        theme.primaryColor.opacity(0.4)
                            .frame(width: geo.size.width * (1.0 - progress))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .allowsHitTesting(false)
            
            HStack(spacing: 12) {
                if let iconName = counter.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 24)
                }
                Text(counter.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(counter.value)")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white)
                    if let goal = counter.goalValue {
                        Text("/ \(goal)")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
        }
        .frame(height: 44)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            isActive = true
        }
        .background(
            NavigationLink(destination: CounterDetailView(counter: counter), isActive: $isActive) {
                EmptyView()
            }
            .opacity(0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        // .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview
#Preview {
    do {
        let container = try ModelContainer(
            for: Counter.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return NavigationStack {
            ContentView()
                .modelContainer(container)
        }
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

// MARK: - NewCollectionView
//struct NewCollectionView: View {
//    var onDismiss: () -> Void
//    var onAdd: (String, String?) -> Void
//    @State private var name = ""
//    @State private var iconName: String? = "folder"
//    @State private var showingSymbolPicker = false
//    var body: some View {
//        Form {
//            Section(header: Text("Collection Name")) {
//                TextField("Name", text: $name)
//            }
//            Section(header: Text("Icon")) {
//                Button {
//                    showingSymbolPicker = true
//                } label: {
//                    HStack {
//                        Text("Icon")
//                        Spacer()
//                        if let icon = iconName {
//                            Image(systemName: icon)
//                                .foregroundColor(.accentColor)
//                        } else {
//                            Text("None")
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                }
//            }
//        }
//        .navigationTitle("New Collection")
//        .toolbar {
//            ToolbarItem(placement: .cancellationAction) {
//                Button("Cancel") { onDismiss() }
//            }
//            ToolbarItem(placement: .confirmationAction) {
//                Button("Add") {
//                    onAdd(name, iconName)
//                    onDismiss()
//                }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
//            }
//        }
//        .sheet(isPresented: $showingSymbolPicker) {
//            NavigationStack {
//                SymbolGridView(selectedSymbolName: $iconName)
//            }
//        }
//    }
//}

// MARK: - Drag & Drop Delegates
//struct CounterDropDelegate: DropDelegate {
//    let targetCounter: Counter
//    let modelContext: ModelContext
//    @Binding var isTargeted: Bool
//    let parentCollection: CounterCollection
//    @Binding var draggedCounter: Counter?
//    
//    func performDrop(info: DropInfo) -> Bool {
//        guard let dragged = draggedCounter else { return false }
//        // Move counter to new collection if needed
//        if dragged.collection != parentCollection {
//            dragged.collection?.counters.removeAll { $0 === dragged }
//            dragged.collection = parentCollection
//            parentCollection.counters.append(dragged)
//        }
//        // Reorder within collection
//        let counters = parentCollection.counters.sorted(by: { $0.order < $1.order })
//        if let from = counters.firstIndex(where: { $0 === dragged }), let to = counters.firstIndex(where: { $0 === targetCounter }) {
//            var mutable = counters
//            mutable.move(fromOffsets: IndexSet(integer: from), toOffset: to)
//            for (index, counter) in mutable.enumerated() {
//                counter.order = index
//            }
//        }
//        draggedCounter = nil
//        return true
//    }
//    func dropEntered(info: DropInfo) { isTargeted = true }
//    func dropExited(info: DropInfo) { isTargeted = false }
//    func dropUpdated(info: DropInfo) -> DropProposal? { .init(operation: .move) }
//}

struct CollectionEndDropDelegate: DropDelegate {
    let collection: CounterCollection
    let modelContext: ModelContext
    @Binding var draggedCounter: Counter?
    func performDrop(info: DropInfo) -> Bool {
        guard let dragged = draggedCounter else { return false }
        if dragged.collection != collection {
            dragged.collection?.counters.removeAll { $0 === dragged }
            dragged.collection = collection
            collection.counters.append(dragged)
        }
        // Place at end
        let counters = collection.counters.sorted(by: { $0.order < $1.order })
        if let from = counters.firstIndex(where: { $0 === dragged }) {
            var mutable = counters
            mutable.move(fromOffsets: IndexSet(integer: from), toOffset: counters.count)
            for (index, counter) in mutable.enumerated() {
                counter.order = index
            }
        }
        draggedCounter = nil
        return true
    }
    func dropEntered(info: DropInfo) {}
    func dropExited(info: DropInfo) {}
    func dropUpdated(info: DropInfo) -> DropProposal? { .init(operation: .move) }
}

// MARK: - Drag & Drop Delegate (top-level, @MainActor)
@MainActor
class CounterDropDelegate: DropDelegate {
    let targetCounter: Counter
    let modelContext: ModelContext
    
    init(targetCounter: Counter, modelContext: ModelContext) {
        self.targetCounter = targetCounter
        self.modelContext = modelContext
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: ["public.text"]).first else { return false }
        
        itemProvider.loadDataRepresentation(forTypeIdentifier: "public.text") { data, error in
            guard let data = data,
                  let id = String(data: data, encoding: .utf8),
                  let sourceCounter = DragDropUtils.fetchCounter(from: id, context: self.modelContext) else {
                return
            }
            // Update order of counters
            sourceCounter.order = self.targetCounter.order
        }
        return true
    }
    
    func dropEntered(info: DropInfo) {}
    func dropExited(info: DropInfo) {}
    func dropUpdated(info: DropInfo) -> DropProposal? { .init(operation: .move) }
}

// Custom reorderable stack for counters
private struct CustomReorderableStack: View {
    let counters: [Counter]
    let collection: CounterCollection?
    @Binding var draggingCounter: Counter?
    @Binding var dragOverIndex: Int?
    let moveAction: (CounterCollection?, IndexSet, Int) -> Void
    
    var body: some View {
        // Use List with .onMove for smooth native reordering within a collection
        List {
        ForEach(Array(counters.enumerated()), id: \ .element.uuid) { idx, counter in
                CounterRowView(counter: counter)
                    
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemGroupedBackground).opacity(0.7))
                            .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
                    )
                    .scaleEffect(draggingCounter == counter ? 1.04 : 1.0)
                    .opacity(draggingCounter == counter ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 0.18), value: draggingCounter == counter)
                    .onDrag {
                        draggingCounter = counter
                        return NSItemProvider(object: counter.uuid.uuidString as NSString)
                    }
            }
            .onMove { indices, newOffset in
                moveAction(collection, indices, newOffset)
            }
        }
        .listStyle(.plain)
        .frame(maxHeight: CGFloat(counters.count) * 54 + 10)
    }
}

// Helper view for a draggable and droppable counter row
private struct DraggableCounterRow: View {
    let counter: Counter
    let collectionID: UUID?
    let idx: Int
    let isDropTarget: Bool
    let onDrag: () -> Void
    let onDrop: ([NSItemProvider]) -> Bool
    @Binding var dragOverIndex: (collection: UUID?, index: Int)?

    var body: some View {
        VStack(spacing: 0) {
            CounterRowView(counter: counter)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
                .padding(.horizontal, 4)
                .animation(.easeInOut(duration: 0.25), value: counter.order)
                .onDrag {
                    onDrag()
                    return DragDropUtils.createItemProvider(for: counter)
                }
                .onDrop(of: ["public.text"], isTargeted: Binding(
                    get: { isDropTarget },
                    set: { isTargeted in
                        dragOverIndex = isTargeted ? (collectionID, idx) : nil
                    }
                ), perform: { providers in
                    let result = onDrop(providers)
                    dragOverIndex = nil
                    return result
                })
        }
    }
}

// Custom drop target view
private struct DropTargetView: View {
    let collection: CounterCollection?
    @Binding var isTargeted: Bool
    let onDrop: ([NSItemProvider]) -> Bool
    var body: some View {
        Rectangle()
            .fill(isTargeted ? Color(UIColor.quaternaryLabel) : Color.clear)
            .frame(height: 24)
            .cornerRadius(8)
            .onDrop(of: ["public.text"], isTargeted: $isTargeted, perform: onDrop)
            .padding(.vertical, 4)
    }
}

struct SectionDropDelegate: DropDelegate {
    let collection: CounterCollection?
    let allCounters: [Counter]
    let collections: [CounterCollection]
    let context: ModelContext
    let atIndex: Int
    let onDropComplete: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: ["public.text"]).first else { return false }
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { (item, error) in
            var idString: String?
            if let data = item as? Data {
                idString = String(data: data, encoding: .utf8)
            } else if let str = item as? String {
                idString = str
            }
            guard let idString,
                  let counter = DragDropUtils.fetchCounter(from: idString, context: context) else { return }
            DispatchQueue.main.async {
                // Remove from old collection if needed
                if let oldCollection = counter.collection {
                    oldCollection.counters.removeAll { $0 === counter }
                    let oldCounters = oldCollection.counters.sorted(by: { $0.order < $1.order })
                    for (idx, c) in oldCounters.enumerated() { c.order = idx }
                    oldCollection.counters = oldCounters
                } else {
                    let unassigned = allCounters.filter { $0.collection == nil }.sorted(by: { $0.order < $1.order })
                    let filtered = unassigned.filter { $0 !== counter }
                    for (idx, c) in filtered.enumerated() { c.order = idx }
                }
                // Assign to new collection (or nil)
                counter.collection = collection
                if let collection = collection {
                    var counters = collection.counters.sorted(by: { $0.order < $1.order })
                    counters.removeAll { $0 === counter }
                    counters.insert(counter, at: atIndex)
                    for (idx, c) in counters.enumerated() { c.order = idx }
                    collection.counters = counters
                } else {
                    var unassigned = allCounters.filter { $0.collection == nil && $0 !== counter }.sorted(by: { $0.order < $1.order })
                    unassigned.insert(counter, at: atIndex)
                    for (idx, c) in unassigned.enumerated() { c.order = idx; c.collection = nil }
                }
                onDropComplete()
            }
        }
        return true
    }
}

