//
//  ContentView.swift
//  FlyAway
//
//  Created by sara jakubowicz on 2/6/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingMenu = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
                .tag(1)
            
            CreateThoughtView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            MenuView()
                .tabItem {
                    Label("Menu", systemImage: "line.3.horizontal")
                }
                .tag(3)
        }
        .accentColor(.purple)
    }
}

struct MenuView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: MessagesView()) {
                    Label("Messages", systemImage: "message.fill")
                        .font(.body)
                }
                
                NavigationLink(destination: MindfulnessView()) {
                    Label("Mindfulness", systemImage: "leaf.fill")
                        .font(.body)
                }
                
                NavigationLink(destination: ProfileView()) {
                    Label("Profile", systemImage: "person.fill")
                        .font(.body)
                }
            }
            .navigationTitle("More")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(ThoughtManager())
}
