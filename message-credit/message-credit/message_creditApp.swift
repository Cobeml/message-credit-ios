//
//  message_creditApp.swift
//  message-credit
//
//  Created by Cobe Liu on 8/23/25.
//

import SwiftUI

@main
struct message_creditApp: App {
    @StateObject private var shortcutsManager = ShortcutsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(shortcutsManager)
                .onOpenURL { url in
                    shortcutsManager.handleIncomingURL(url)
                }
        }
    }
}
