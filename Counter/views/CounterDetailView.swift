//
//  ContentView.swift
//  Counter
//
//  Created by Murray Buchanan on 13/05/2025.
//

import SwiftUI

struct CounterDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Bindable var counter: Counter
    @State private var showingEditSheet = false
    @State private var showingProgressSheet = false
    @State private var showingInsights = false
    @State private var isGoalReached = false
    
    private var theme: Theme {
        ThemeManager.shared.theme(for: counter)
    }
    
    var body: some View {
        ZStack {
            theme.gradient
                .opacity(counter.goalValue == nil || counter.value >= counter.goalValue! ? 1 : 0.7)
                .ignoresSafeArea()
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: counter.value)
            
            VStack {
                Spacer()
                
                // Value & Goal
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(counter.value)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: counter.value)
                    if let goal = counter.goalValue {
                        Text("/ \(goal)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.7))
                            .foregroundColor(.white)
                            .shadow(color: Color.white.opacity(0.4), radius: 4, x: 0, y: 0)
                    }
                }
                
                Spacer()
                
                // Control Buttons
                HStack(spacing: 40) {
                    controlButton(label: "−") { changeValue(by: -1) }
                    controlButton(label: "+") { changeValue(by: 1) }
                }
            }
        }
        .navigationTitle(counter.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit", systemImage: "slider.horizontal.below.square.filled.and.square")
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarHidden(false)
        .statusBar(hidden: true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.clear, for: .navigationBar)
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                EditCounterView(counter: counter)
            }
        }
    }
    
    private func controlButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.3))
                )
        }
    }
    
    private func changeValue(by amount: Int) {
        withAnimation {
            counter.value += amount * counter.step
            counter.lastUpdated = Date()
        }
    }
}
