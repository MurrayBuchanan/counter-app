//
//  SymbolGridView.swift
//  Counter
//
//  Created by Murray Buchanan on 14/05/2025.
//

import SwiftUI
import SwiftData

struct SymbolGridView: View {
    @Binding var selectedSymbolName: String?
    var name: Binding<String>? = nil // Make name optional
    @Binding var didConfirm: Bool // NEW: Track confirmation
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory = 0
    // Name field
    @State private var tempSelectedSymbol: String? = "plus.square"
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var navTitle: String = "Objects"
    @FocusState private var nameFieldFocused: Bool
    @State private var sectionFrames: [Int: CGRect] = [:]
    @State private var isProgrammaticScroll = false

    let categories = ["Objects", "People", "Symbols"]

    let objectSymbols = [
        "folder", "tray", "doc", "calendar", "envelope", "laptopcomputer", "printer", "externaldrive", "mic", "message", "paperplane", "creditcard", "keyboard", "archivebox", "cube", "pencil", "paintbrush", "hammer", "wrench", "iphone", "desktopcomputer", "cart", "gift", "tag", "star", "bell", "plus.square", "book", "bookmark", "camera", "car", "clock"
    ]
    let peopleSymbols = [
        "person", "person.2", "person.3", "person.crop.circle", "person.crop.square", "bubble.left", "graduationcap", "briefcase", "person.badge.plus", "person.badge.minus", "person.2.circle", "person.3.sequence", "person.crop.rectangle", "person.crop.circle.badge.checkmark", "person.crop.circle.badge.xmark", "person.crop.circle.badge.exclam", "person.crop.circle.badge.questionmark", "person.icloud", "person.wave.2", "person.2.wave.2", "person.crop.artframe", "person.crop.square.filled.and.at.rectangle", "person.text.rectangle", "person.icloud"
    ]
    let symbolSymbols = [
        "star", "heart", "bolt", "flame", "moon", "cloud", "sun.max", "leaf", "flag", "bookmark", "tag", "gift", "crown", "cube", "circle", "square", "triangle", "hexagon", "diamond", "circle.grid.cross", "star.square", "heart.square", "bolt.square", "flame", "moon", "cloud", "sun.max", "leaf", "flag", "bookmark", "tag", "gift"
    ]

    var allSymbols: [String] { objectSymbols + peopleSymbols + symbolSymbols }
    var categoryRanges: [Range<Int>] {
        let objects = 0..<objectSymbols.count
        let people = objects.upperBound..<(objects.upperBound + peopleSymbols.count)
        let symbols = people.upperBound..<(people.upperBound + symbolSymbols.count)
        return [objects, people, symbols]
    }

    let rows = Array(repeating: GridItem(.flexible(), spacing: 20), count: 4)

    // Helper: Calculate pixel offset for each category's start (multi-row grid aware)
    var categoryPixelOffsets: [CGFloat] {
        let symbolWidth: CGFloat = 52 + 24 // width + spacing
        let symbolsPerColumn = 4
        var offsets: [CGFloat] = []
        var currentIdx = 0
        for range in categoryRanges {
            let startColumn = currentIdx / symbolsPerColumn
            offsets.append(CGFloat(startColumn) * symbolWidth)
            currentIdx += range.count
        }
        // Add the end of the last category for easier comparison
        let totalColumns = (allSymbols.count + symbolsPerColumn - 1) / symbolsPerColumn
        offsets.append(CGFloat(totalColumns) * symbolWidth)
        return offsets
    }

    private func symbolsForCategory(_ idx: Int) -> [String] {
        switch idx {
        case 0: return objectSymbols
        case 1: return peopleSymbols
        case 2: return symbolSymbols
        default: return []
        }
    }

    private func updateSelectedCategory(visibleFrame: CGRect) {
        if isProgrammaticScroll { return }
        // Find the section with the largest intersection with the visible frame
        let intersections = sectionFrames.mapValues { $0.intersection(visibleFrame).width }
        if let (maxIdx, _) = intersections.max(by: { $0.value < $1.value }), selectedCategory != maxIdx {
            DispatchQueue.main.async {
                withAnimation {
                    selectedCategory = maxIdx
                }
            }
        }
    }

    private var symbolGrid: some View {
        GeometryReader { outerGeo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(0..<categories.count, id: \.self) { catIdx in
                            GeometryReader { geo in
                                LazyHGrid(rows: rows, spacing: 24) {
                                    ForEach(symbolsForCategory(catIdx).enumerated().map { $0 }, id: \ .offset) { idx, symbol in
                                        Button(action: {
                                            tempSelectedSymbol = symbol
                                        }) {
                                            ZStack {
                                                if tempSelectedSymbol == symbol {
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill(Color(.systemGray5))
                                                        .frame(width: 52, height: 52)
                                                }
                                                Image(systemName: symbol)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 36, height: 36)
                                                    .foregroundColor(.gray)
                                            }
                                            .frame(width: 52, height: 52)
                                        }
                                        .id(catIdx * 1000 + idx)
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding()
                                .onAppear {
                                    sectionFrames[catIdx] = geo.frame(in: .global)
                                }
                                .onChange(of: geo.frame(in: .global)) { newFrame in
                                    sectionFrames[catIdx] = newFrame
                                    updateSelectedCategory(visibleFrame: outerGeo.frame(in: .global))
                                }
                            }
                            .frame(width: max(outerGeo.size.width, CGFloat((symbolsForCategory(catIdx).count + 3) / 4) * (52 + 24)))
                        }
                    }
                }
                .onAppear {
                    scrollProxy = proxy
                    tempSelectedSymbol = selectedSymbolName ?? "plus.square"
                    navTitle = categories[selectedCategory]
                    if name != nil { nameFieldFocused = true }
                }
            }
            .frame(height: 4 * 44 + 3 * 24 + 32)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Selected icon preview
                if let selected = tempSelectedSymbol {
                    Image(systemName: selected)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .foregroundColor(.gray)
                        .padding(.top, 136)
                        .padding(.bottom, name != nil ? 40 : 152)
                }
                // Name field below icon if binding provided
                if let name = name {
                    TextField("", text: name)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .focused($nameFieldFocused)
                        .padding(.bottom, 96)
                        .padding(.horizontal)
                }
                // Category picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(0..<categories.count, id: \.self) { i in
                        Text(categories[i])
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .animation(.default, value: selectedCategory)
                .onChange(of: selectedCategory) { newValue in
                    isProgrammaticScroll = true
                    withAnimation {
                        scrollProxy?.scrollTo(newValue * 1000, anchor: .leading)
                    }
                    navTitle = categories[newValue]
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isProgrammaticScroll = false
                    }
                }
                .padding(.bottom, 8)
                // Icon picking section
                symbolGrid
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(name != nil ? "New Collection" : "Counter Icon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(name != nil ? "Add" : "Select") {
                    selectedSymbolName = tempSelectedSymbol
                    didConfirm = true // NEW: Signal confirmation
                    dismiss()
                }
                .disabled(tempSelectedSymbol == nil || (name != nil && name!.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
        }
    }
}

// Helper for scroll offset
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
