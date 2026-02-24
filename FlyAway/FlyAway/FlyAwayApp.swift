//
//  FlyAwayApp.swift
//  FlyAway
//
//  Created by sara jakubowicz on 2/6/26.
//

import SwiftUI
import FirebaseCore

@main
struct FlyAwayApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var thoughtManager = ThoughtManager()
    @StateObject private var milestoneManager = MilestoneManager()
    @StateObject private var moodManager = MoodManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(thoughtManager)
                .environmentObject(milestoneManager)
                .environmentObject(moodManager)
        }
    }
}
