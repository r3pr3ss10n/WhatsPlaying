//
//  WhatsPlayingApp.swift
//  WhatsPlaying
//
//  Created by key on 22.07.2025.
//

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
