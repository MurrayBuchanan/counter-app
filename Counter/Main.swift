//
//  Main.swift
//  Counter
//
//  Created by Murray Buchanan on 14/05/2025.
//

import SwiftUI
import SwiftData

@main
struct CounterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Counter.self, CounterCollection.self])
        }
    }
}
