import Foundation
import SwiftData
import SwiftUI

@Model
final class CounterCollection {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Counter.collection)
    var counters: [Counter] = []
    var order: Int = 0
    var isExpanded: Bool = true
    var iconName: String? = nil
    
    init(name: String, order: Int = 0, iconName: String? = nil) {
        self.name = name
        self.order = order
        self.iconName = iconName
    }
}

@Model
final class Counter {
    var name: String
    var value: Int
    var dailyIncrement: Int
    var step: Int
    var createdAt: Date
    var iconName: String?
    var notes: String?
    var lastUpdated: Date
    var order: Int
    var uuid: UUID = UUID()
    
    // Goal-related properties
    var goalValue: Int?
    var goalDate: Date?
    var isCountingUp: Bool
    
    // Theme selection
    var themeName: String
    
    weak var collection: CounterCollection?
    
    init(
        name: String,
        value: Int = 0,
        dailyIncrement: Int = 1,
        step: Int = 1,
        createdAt: Date = Date(),
        iconName: String? = nil,
        notes: String? = nil,
        goalValue: Int? = nil,
        goalDate: Date? = nil,
        isCountingUp: Bool = true,
        order: Int = 0,
        themeName: String = "Sunset",
        collection: CounterCollection? = nil,
        uuid: UUID = UUID()
    ) {
        self.name = name
        self.value = value
        self.dailyIncrement = dailyIncrement
        self.step = step
        self.createdAt = createdAt
        self.iconName = iconName
        self.notes = notes
        self.lastUpdated = createdAt
        self.goalValue = goalValue
        self.goalDate = goalDate
        self.isCountingUp = isCountingUp
        self.order = order
        self.themeName = themeName
        self.collection = collection
        self.uuid = uuid
    }
    
    /// Whether the counter has met its goal.
    var hasReachedGoal: Bool {
        guard let goal = goalValue else { return false }
        return isCountingUp ? value >= goal : value <= 0
    }
}
