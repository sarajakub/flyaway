import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var thoughtManager: ThoughtManager
    @State private var showingSavedThoughts = false
    @State private var showingSettings = false
    @State private var showingSignOutConfirm = false
    @State private var thoughtCount = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(authManager.currentUser?.displayName.prefix(1).uppercased() ?? "?")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(spacing: 4) {
                        Text(authManager.currentUser?.displayName ?? "User")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(authManager.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 40) {
                        StatView(number: authManager.currentUser?.followerCount ?? 0, label: "Followers")
                        StatView(number: authManager.currentUser?.followingCount ?? 0, label: "Following")
                        StatView(number: thoughtCount, label: "Thoughts")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                .padding()
                .task {
                        await thoughtManager.fetchUserThoughts()
                        thoughtCount = thoughtManager.thoughts.count
                    }
                    
                    if let bio = authManager.currentUser?.bio {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.headline)
                            Text(bio)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    VStack(spacing: 0) {
                        Button(action: { showingSavedThoughts = true }) {
                            MenuItemView(icon: "bookmark.fill", title: "Saved Thoughts", color: .purple)
                        }
                        Divider().padding(.leading, 60)
                        NavigationLink(destination: EmotionTrackingView()) {
                            MenuItemView(icon: "heart.text.square.fill", title: "Emotion Tracking", color: .pink)
                        }
                        Divider().padding(.leading, 60)
                        NavigationLink(destination: MyJourneyView()) {
                            MenuItemView(icon: "chart.line.uptrend.xyaxis", title: "My Journey", color: .blue)
                        }
                        Divider().padding(.leading, 60)
                        NavigationLink(destination: MindfulnessView()) {
                            MenuItemView(icon: "leaf.fill", title: "Mindfulness", color: .green)
                        }
                        Divider().padding(.leading, 60)
                        Button(action: { showingSettings = true }) {
                            MenuItemView(icon: "gear", title: "Settings", color: .gray)
                        }
                        Divider().padding(.leading, 60)
                        NavigationLink(destination: HelpSupportView()) {
                            MenuItemView(icon: "questionmark.circle", title: "Help & Support", color: .orange)
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    Button(action: {
                        showingSignOutConfirm = true
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSavedThoughts) {
                SavedThoughtsSheet(thoughtManager: thoughtManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet(authManager: authManager)
            }
            .confirmationDialog("Sign Out", isPresented: $showingSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

struct StatView: View {
    let number: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(number)")
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct SavedThoughtsSheet: View {
    @ObservedObject var thoughtManager: ThoughtManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if thoughtManager.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if thoughtManager.savedThoughts.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 80))
                            .foregroundColor(.purple.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No Saved Thoughts")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Thoughts you save from the community will appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(thoughtManager.savedThoughts) { thought in
                                ThoughtCard(thought: thought)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            Task {
                                                await thoughtManager.unsaveThought(thought)
                                            }
                                        } label: {
                                            Label("Remove from Saved", systemImage: "bookmark.slash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Saved Thoughts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await thoughtManager.fetchSavedThoughts()
            }
            .refreshable {
                await thoughtManager.fetchSavedThoughts()
            }
        }
    }
}

struct SettingsSheet: View {
    @ObservedObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authManager.currentUser?.email ?? "")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Preferences") {
                    Toggle("Notifications", isOn: .constant(true))
                    Toggle("Public Profile", isOn: .constant(true))
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    NavigationLink("Privacy Policy") {
                        Text("Privacy Policy - Coming Soon")
                    }
                    NavigationLink("Terms of Service") {
                        Text("Terms of Service - Coming Soon")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
        .environmentObject(ThoughtManager())
}
