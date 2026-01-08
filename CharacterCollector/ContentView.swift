import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    init() {
        // Configure navigation bar appearance for white text
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.theme.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Label("Capture", systemImage: "camera.fill")
                }
                .tag(0)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(1)

            StudyView()
                .tabItem {
                    Label("Study", systemImage: "rectangle.on.rectangle.angled")
                }
                .tag(2)
        }
        .tint(Color.theme.primary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CharacterCard.self, inMemory: true)
}
