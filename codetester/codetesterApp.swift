import SwiftUI

@main
struct codetesterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
    }
}