//
//  ContentView.swift
//  FlyAway
//
//  Created by sara jakubowicz on 2/6/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if authManager.isAuthenticated {
                    if hasSeenOnboarding {
                        MainTabView()
                    } else {
                        OnboardingView()
                    }
                } else {
                    AuthenticationView()
                }
            }

            if !networkMonitor.isConnected {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.caption.weight(.semibold))
                .accessibilityHidden(true)
            Text("You're offline — changes will sync when reconnected")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.purple.opacity(0.9))
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
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
            
            NavigationStack {
                MessagesView()
            }
            .tabItem {
                Label("Messages", systemImage: "message.fill")
            }
            .tag(3)
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(4)
        }
        .accentColor(.purple)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(ThoughtManager())
        .environmentObject(MilestoneManager())
        .environmentObject(MoodManager())
        .environmentObject(NetworkMonitor())
}
