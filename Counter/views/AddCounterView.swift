//
//  ContentView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI
import SwiftData

struct AddCounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let collections: [CounterCollection]
    @State private var selectedCollection: CounterCollection? = nil
    @State private var name = ""
    @State private var value: Int = 0
    @State private var dailyIncrement = 1
    @State private var step: Int = 1
    @State private var iconName: String? = "plus.square"
    @State private var selectedThemeName: String = "Sunset"
    @State private var showingSymbolPicker = false
    
    // Goal-related states
    @State private var hasGoal = false
    @State private var goalValue: Int = 1
    @State private var goalDate = Date()
    @State private var isCountingUp = true
    @State private var didConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    
                    Stepper(value: $value, in: 0...9999) {
                        HStack {
                            Text("Start Value")
                            Spacer()
                            Text("\(value)")
                        }
                    }
                    
                    Stepper(value: $dailyIncrement, in: 1...100) {
                        HStack {
                            Text("Daily Increment")
                            Spacer()
                            Text("\(dailyIncrement)")
                        }
                    }
                    
                    Stepper(value: $step, in: 1...100) {
                        HStack {
                            Text("Step Size")
                            Spacer()
                            Text("\(step)")
                        }
                    }
                }
                
                if !collections.isEmpty {
                    Section("Assign to Collection") {
                        Picker("Collection", selection: $selectedCollection) {
                            Text("Unassigned").tag(Optional<CounterCollection>(nil))
                            ForEach(collections) { collection in
                                Text(collection.name).tag(Optional(collection))
                            }
                        }
                    }
                }

                Section("Goal") {
                    Toggle("Set Goal", isOn: $hasGoal)
                    
                    if hasGoal {
                        Stepper(value: $goalValue, in: 1...9999) {
                            HStack {
                                Text("Target Value")
                                Spacer()
                                Text("\(goalValue)")
                            }
                        }
                        
                        DatePicker("Target Date", selection: $goalDate, displayedComponents: .date)
                        
                        Toggle("Count Up", isOn: $isCountingUp)
                    }
                }
                
                Section("Design") {
                    Button {
                        showingSymbolPicker = true
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            if let icon = iconName {
                                Image(systemName: icon)
                                    .foregroundColor(ThemeManager.shared.theme(for: selectedThemeName).primaryColor)
                            } else {
                                Text("None")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    let columns = Array(repeating: GridItem(.fixed(40), spacing: 16), count: 6)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Theme.allThemes.prefix(12)) { theme in
                            ZStack {
                                Circle()
                                    .fill(theme.gradient)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
                                    .onTapGesture {
                                        selectedThemeName = theme.name
                                    }
                                if selectedThemeName == theme.name {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.accentColor).frame(width: 16, height: 16))
                                        .frame(width: 16, height: 16)
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCounter()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingSymbolPicker) {
                NavigationStack {
                    SymbolGridView(selectedSymbolName: $iconName, didConfirm: $didConfirm)
                }
            }
        }
    }

    private func addCounter() {
        let counter = Counter(
            name: name,
            value: value,
            dailyIncrement: dailyIncrement,
            step: step,
            iconName: iconName,
            goalValue: hasGoal ? goalValue : nil,
            goalDate: hasGoal ? goalDate : nil,
            isCountingUp: isCountingUp,
            themeName: selectedThemeName,
            collection: selectedCollection
        )
        context.insert(counter)
        if let collection = selectedCollection {
            var counters = collection.counters.sorted(by: { $0.order < $1.order })
            counters.append(counter)
            for (idx, c) in counters.enumerated() { c.order = idx }
            collection.counters = counters
        }
        dismiss()
    }
}

struct AddCounterView_Previews: PreviewProvider {
    static var previews: some View {
        AddCounterView(collections: [])
            .modelContainer(for: Counter.self, inMemory: true)
    }
}
