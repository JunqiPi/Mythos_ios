import SwiftUI

// MARK: - App Entry Point
@main
struct MythosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Default to dark mode
        }
    }
}