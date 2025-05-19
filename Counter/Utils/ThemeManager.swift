import SwiftUI

struct Theme: Identifiable {
    let id = UUID()
    let name: String
    let gradient: LinearGradient
    let primaryColor: Color
    let secondaryColor: Color
    
    static let allThemes: [Theme] = [
        Theme(
            name: "Blue",
            gradient: LinearGradient(
                colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.0, green: 0.35, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 0.0, green: 0.48, blue: 1.0),
            secondaryColor: Color(red: 0.0, green: 0.35, blue: 0.85)
        ),
        Theme(
            name: "Indigo",
            gradient: LinearGradient(
                colors: [Color(red: 0.35, green: 0.35, blue: 0.95), Color(red: 0.25, green: 0.25, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 0.35, green: 0.35, blue: 0.95),
            secondaryColor: Color(red: 0.25, green: 0.25, blue: 0.85)
        ),
        Theme(
            name: "Purple",
            gradient: LinearGradient(
                colors: [Color(red: 0.65, green: 0.35, blue: 0.95), Color(red: 0.55, green: 0.25, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 0.65, green: 0.35, blue: 0.95),
            secondaryColor: Color(red: 0.55, green: 0.25, blue: 0.85)
        ),
        Theme(
            name: "Pink",
            gradient: LinearGradient(
                colors: [Color(red: 1.0, green: 0.35, blue: 0.65), Color(red: 0.9, green: 0.25, blue: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 1.0, green: 0.35, blue: 0.65),
            secondaryColor: Color(red: 0.9, green: 0.25, blue: 0.55)
        ),
        Theme(
            name: "Red",
            gradient: LinearGradient(
                colors: [Color(red: 1.0, green: 0.25, blue: 0.25), Color(red: 0.9, green: 0.15, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 1.0, green: 0.25, blue: 0.25),
            secondaryColor: Color(red: 0.9, green: 0.15, blue: 0.15)
        ),
        Theme(
            name: "Orange",
            gradient: LinearGradient(
                colors: [Color(red: 1.0, green: 0.6, blue: 0.0), Color(red: 0.9, green: 0.5, blue: 0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 1.0, green: 0.6, blue: 0.0),
            secondaryColor: Color(red: 0.9, green: 0.5, blue: 0.0)
        ),
        Theme(
            name: "Yellow",
            gradient: LinearGradient(
                colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 0.9, green: 0.7, blue: 0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 1.0, green: 0.8, blue: 0.0),
            secondaryColor: Color(red: 0.9, green: 0.7, blue: 0.0)
        ),
        Theme(
            name: "Green",
            gradient: LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.1, green: 0.7, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 0.2, green: 0.8, blue: 0.4),
            secondaryColor: Color(red: 0.1, green: 0.7, blue: 0.3)
        ),
        Theme(
            name: "Teal",
            gradient: LinearGradient(
                colors: [Color(red: 0.0, green: 0.8, blue: 0.8), Color(red: 0.0, green: 0.7, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 0.0, green: 0.8, blue: 0.8),
            secondaryColor: Color(red: 0.0, green: 0.7, blue: 0.7)
        ),
        Theme(
            name: "Mint",
            gradient: LinearGradient(
                colors: [Color(red: 0.0, green: 0.9, blue: 0.8), Color(red: 0.0, green: 0.8, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 0.0, green: 0.9, blue: 0.8),
            secondaryColor: Color(red: 0.0, green: 0.8, blue: 0.7)
        ),
        Theme(
            name: "Gray",
            gradient: LinearGradient(
                colors: [Color(red: 0.6, green: 0.6, blue: 0.6), Color(red: 0.5, green: 0.5, blue: 0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 0.6, green: 0.6, blue: 0.6),
            secondaryColor: Color(red: 0.5, green: 0.5, blue: 0.5)
        ),
        Theme(
            name: "Brown",
            gradient: LinearGradient(
                colors: [Color(red: 0.6, green: 0.4, blue: 0.2), Color(red: 0.5, green: 0.3, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            primaryColor: Color(red: 0.6, green: 0.4, blue: 0.2),
            secondaryColor: Color(red: 0.5, green: 0.3, blue: 0.1)
        )
    ]
    
    static func theme(for name: String) -> Theme {
        allThemes.first { $0.name == name } ?? allThemes[0]
    }
}

class ThemeManager {
    static let shared = ThemeManager()
    
    private init() {}
    
    func theme(for counter: Counter) -> Theme {
        Theme.theme(for: counter.themeName)
    }
    
    func theme(for name: String) -> Theme {
        Theme.theme(for: name)
    }
    
    func randomTheme() -> Theme {
        Theme.allThemes.randomElement() ?? Theme.allThemes[0]
    }
} 