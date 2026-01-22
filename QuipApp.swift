//
//  QuipApp.swift
//  Quip
//
//  Created by Max Stober on 1/14/26.
//

import SwiftUI
import SwiftData

@main
struct QuipApp: App {
    let container: ModelContainer
    let activityManager = ActivityManager()

    init() {
        self.container = DataManager.shared.container
        
        // Seed Data handled by DataManager
        DataManager.shared.seedDataIfNeeded(activityManager: activityManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(activityManager)
        }
        .modelContainer(container)
    }
}

// Duplicate imports removed

// Removed @Observable final class ActivityManager - duplicate removed as instructed

// Model definitions have been moved to separate files (User.swift, FriendLevel.swift, Activity.swift, Interest.swift, GroupSession.swift).


