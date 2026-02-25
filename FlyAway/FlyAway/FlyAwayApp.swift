//
//  FlyAwayApp.swift
//  FlyAway
//
//  Created by sara jakubowicz on 2/6/26.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct FlyAwayApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var thoughtManager = ThoughtManager()
    @StateObject private var milestoneManager = MilestoneManager()
    @StateObject private var moodManager = MoodManager()
    @StateObject private var networkMonitor = NetworkMonitor()

    init() {
        FirebaseApp.configure()

        // Enable Firestore offline persistence (up to 100 MB local cache)
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber)
        db.settings = settings

        // Request notification permission early so the system prompt appears naturally
        NotificationManager.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(thoughtManager)
                .environmentObject(milestoneManager)
                .environmentObject(moodManager)
                .environmentObject(networkMonitor)
        }
    }
}
