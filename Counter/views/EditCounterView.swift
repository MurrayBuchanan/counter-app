import SwiftUI

struct EditCounterView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var counter: Counter
    
    @State private var name: String
    @State private var selectedThemeName: String
    @State private var iconName: String?
    @State private var showingSymbolPicker = false
    @State private var dailyIncrement: Int
    @State private var step: Int
    @State private var goalValue: Int
    @State private var goalDate: Date
    @State private var isCountingUp: Bool
    @State private var didConfirm = false
    
    init(counter: Counter) {
        self.counter = counter
        _name = State(initialValue: counter.name)
        _selectedThemeName = State(initialValue: counter.themeName)
        _iconName = State(initialValue: counter.iconName)
        _dailyIncrement = State(initialValue: counter.dailyIncrement)
        _step = State(initialValue: counter.step)
        _goalValue = State(initialValue: counter.goalValue ?? 1)
        _goalDate = State(initialValue: counter.goalDate ?? Date())
        _isCountingUp = State(initialValue: counter.isCountingUp)
    }
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $name)
                
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
            
            Section("Goal") {
                Toggle("Set Goal", isOn: Binding(
                    get: { counter.goalValue != nil },
                    set: { hasGoal in
                        if !hasGoal {
                            counter.goalValue = nil
                            counter.goalDate = nil
                        } else {
                            counter.goalValue = goalValue
                            counter.goalDate = goalDate
                        }
                    }
                ))
                
                if counter.goalValue != nil {
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
        .navigationTitle("Edit Counter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(isPresented: $showingSymbolPicker) {
            NavigationStack {
                SymbolGridView(selectedSymbolName: $iconName, name: nil, didConfirm: $didConfirm)
            }
        }
    }
    
    private func saveChanges() {
        counter.name = name
        counter.themeName = selectedThemeName
        counter.iconName = iconName
        counter.dailyIncrement = dailyIncrement
        counter.step = step
        counter.goalValue = counter.goalValue != nil ? goalValue : nil
        counter.goalDate = counter.goalValue != nil ? goalDate : nil
        counter.isCountingUp = isCountingUp
    }
} 
