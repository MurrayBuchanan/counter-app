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
    @State private var selectedCounter: Counter?
    @State private var showNewCollectionSheet = false
    // Enhancement states
    @State private var dragOverCollection: CounterCollection? = nil
    @State private var dragOverUnassigned: Bool = false
    @State private var isDragging: Bool = false
    // Custom reorder states
    @State private var draggingCounter: Counter? = nil
    @State private var dragOverIndex: Int? = nil
    
    private var filteredCollections: [CounterCollection] {
        collections.filter { collection in
            searchText.trimmingCharacters(in: .whitespaces).isEmpty || collection.counters.contains(where: { matchesSearch($0) })
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        unassignedSection
                        collectionSections
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 600)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: collections.map { $0.isExpanded })
                }
                .searchable(text: $searchText)
                .background(Color(.systemGroupedBackground))
                .ignoresSafeArea(edges: .bottom)
                detailView
            }
            .navigationTitle("Counters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showNewCollectionSheet = true
                        } label: {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 20, weight: .medium))
                        }
                        Button {
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                        }
                    }
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
    
    // Filtered counters and collections for search
    private var filteredUnassignedCounters: [Counter] {
        unassignedCounters.filter { matchesSearch($0) }
    }
    private var unassignedCounters: [Counter] {
        allCounters.filter { $0.collection == nil }
    }
    
    private func matchesSearch(_ counter: Counter) -> Bool {
        searchText.trimmingCharacters(in: .whitespaces).isEmpty || counter.name.localizedCaseInsensitiveContains(searchText)
    }
    
    private func filteredCounters(for collection: CounterCollection) -> [Counter] {
        collection.counters.sorted(by: { $0.order < $1.order }).filter { matchesSearch($0) }
    }
    
    @ViewBuilder
    private func sectionView(title: String, counters: [Counter], collection: CounterCollection?, isDropTarget: Bool, onDrop: @escaping ([NSItemProvider]) -> Bool, isExpanded: Bool = true, onToggleExpand: (() -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Icon
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
                // Name
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                // Counter/Goal or Chevron
                HStack(spacing: 4) {
                    if let collection = collection {
                        Text("\(collection.counters.count)")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    if let onToggleExpand, collection != nil {
                        Button(action: onToggleExpand) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                .scaleEffect(isExpanded ? 1.1 : 1.0)
                                .opacity(isExpanded ? 1.0 : 0.85)
                                .animation(nil, value: isExpanded)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 24, alignment: .trailing)
                        .zIndex(1)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDropTarget ? Color.accentColor.opacity(0.18) : Color(.clear))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .onDrop(of: ["public.text"], isTargeted: collection == nil ? $dragOverUnassigned : Binding(
                get: { dragOverCollection == collection },
                set: { isTargeted in dragOverCollection = isTargeted ? collection : nil }
            ), perform: onDrop)
            if isExpanded {
                CustomReorderableStack(
                    counters: counters,
                    collection: collection,
                    draggingCounter: $draggingCounter,
                    dragOverIndex: $dragOverIndex,
                    moveAction: moveCounters
                )
                .padding(.vertical, 4)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(Color.clear)
        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.85, blendDuration: 0.25), value: isExpanded)
    }
    
    @ViewBuilder
    private func counterRow(for counter: Counter, in collection: CounterCollection?) -> some View {
        CounterRowView(counter: counter)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemGroupedBackground).opacity(0.7))
                    .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
            )
            .onDrag {
                isDragging = true
                return NSItemProvider(object: counter.uuid.uuidString as NSString)
            }
            .onTapGesture {
                selectedCounter = counter
            }
            .hoverEffect(.highlight)
            .animation(.easeInOut(duration: 0.18), value: isDragging)
    }
    
    // MARK: - List Sections
    private var unassignedSection: some View {
        Group {
            if !filteredUnassignedCounters.isEmpty {
                sectionView(
                    title: "Unassigned",
                    counters: filteredUnassignedCounters,
                    collection: nil,
                    isDropTarget: dragOverUnassigned,
                    onDrop: { providers in
                        isDragging = false
                        handleDrop(to: nil, at: filteredUnassignedCounters.count, providers: providers)
                        return true
                    }
                )
            } else if collections.isEmpty {
                VStack {
                    Text("No counters or collections found.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
    
    private var collectionSections: some View {
        ForEach(filteredCollections) { collection in
            sectionView(
                title: collection.name,
                counters: filteredCounters(for: collection),
                collection: collection,
                isDropTarget: dragOverCollection == collection,
                onDrop: { providers in
                    isDragging = false
                    handleDrop(to: collection, at: filteredCounters(for: collection).count, providers: providers)
                    return true
                },
                isExpanded: isDragging ? true : collection.isExpanded,
                onToggleExpand: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { collection.isExpanded.toggle() }
                }
            )
        }
    }
    
    // MARK: - Supporting Views
    private var detailView: some View {
        Group {
            if let selected = selectedCounter {
                CounterDetailView(counter: selected)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func moveCounters(in collection: CounterCollection?, from source: IndexSet, to destination: Int) {
        var counters: [Counter]
        if let collection = collection {
            counters = collection.counters.sorted(by: { $0.order < $1.order })
        } else {
            counters = unassignedCounters
        }
        counters.move(fromOffsets: source, toOffset: destination)
        for (index, counter) in counters.enumerated() {
            counter.order = index
            counter.collection = collection
        }
        if let collection = collection {
            collection.counters = counters
        }
    }
    
    // MARK: - Drop Handling
    private func handleDrop(to collection: CounterCollection?, at index: Int, providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { (item, error) in
            var idString: String?
            if let data = item as? Data {
                idString = String(data: data, encoding: .utf8)
            } else if let str = item as? String {
                idString = str
            }
            guard let idString, let counterID = UUID(uuidString: idString), let counter = allCounters.first(where: { $0.uuid == counterID }) else { return }
            DispatchQueue.main.async {
                // Remove from old collection
                if let oldCollection = counter.collection {
                    oldCollection.counters.removeAll { $0 === counter }
                }
                // Assign to new collection (or nil for unassigned)
                counter.collection = collection
                if let collection = collection {
                    var counters = collection.counters.sorted(by: { $0.order < $1.order })
                    counters.insert(counter, at: index)
                    for (idx, c) in counters.enumerated() { c.order = idx }
                    collection.counters = counters
                }
            }
        }
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
            .padding(.horizontal, 12)
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
        ForEach(Array(counters.enumerated()), id: \ .element.uuid) { idx, counter in
            VStack(spacing: 0) {
                DropIndicator(isActive: draggingCounter != nil && dragOverIndex == idx)
                CounterRowView(counter: counter)
                    .padding(.vertical, 2)
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
                    .onDrop(of: ["public.text"], isTargeted: Binding(
                        get: { dragOverIndex == idx },
                        set: { isTargeted in dragOverIndex = isTargeted ? idx : nil }
                    )) { providers in
                        if let dragging = draggingCounter, let from = counters.firstIndex(where: { $0.uuid == dragging.uuid }) {
                            moveAction(collection, IndexSet(integer: from), idx)
                            draggingCounter = nil
                            dragOverIndex = nil
                        }
                        return true
                    }
            }
        }
        // Drop at end
        DropIndicator(isActive: draggingCounter != nil && dragOverIndex == counters.count)
    }
}

private struct DropIndicator: View {
    @Environment(\.colorScheme) private var colorScheme
    var isActive: Bool
    var body: some View {
        Capsule()
            .fill(isActive ? Color.gray.opacity(0.35) : (colorScheme == .dark ? .black : .white))
            .frame(height: 2)
            .blur(radius: isActive ? 0.5 : 0)
            .padding(.horizontal, 8)
            .animation(.easeInOut(duration: 0.18), value: isActive)
    }
}

