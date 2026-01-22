import SwiftUI

@main
struct WhatsPlayingApp: App {
    @StateObject private var menuBarApp = MenuBarApp()

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
