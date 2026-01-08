import SwiftUI
import SwiftData

@main
struct CharacterCollectorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CharacterCard.self, CapturedPhoto.self])
    }
}
