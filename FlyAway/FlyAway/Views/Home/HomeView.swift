import SwiftUI

struct HomeView: View {
    @EnvironmentObject var thoughtManager: ThoughtManager
    @EnvironmentObject var milestoneManager: MilestoneManager
    @EnvironmentObject var moodManager: MoodManager
    @State private var selectedFilter: Thought.ThoughtCategory?
    @State private var showingAddMilestone = false
    @State private var showingMoodCheckIn = false
    @State private var showingCreateThought = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Journey")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Track your healing and growth")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // Daily Mood Check-in Prompt
                    if moodManager.todayMood == nil {
                        Button {
                            showingMoodCheckIn = true
                        } label: {
                            HStack(spacing: 12) {
                                Text("🤔")
                                    .font(.title)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("How are you feeling today?")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Track your emotional journey")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                    } else if let todayMood = moodManager.todayMood {
                        HStack(spacing: 12) {
                            Text(todayMood.moodEmoji)
                                .font(.title)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Mood: \(todayMood.moodLabel)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("Checked in \(todayMood.createdAt, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Milestones Section
                    if !milestoneManager.milestones.isEmpty || showingAddMilestone {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Milestones")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Button {
                                    showingAddMilestone = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding(.horizontal)
                            
                            if milestoneManager.isLoading {
                                ProgressView()
                                    .padding()
                            } else if milestoneManager.milestones.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 40))
                                        .foregroundColor(.purple.opacity(0.6))
                                    
                                    Text("Track important events in your healing journey")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button {
                                        showingAddMilestone = true
                                    } label: {
                                        Text("Add Your First Milestone")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.purple)
                                            .cornerRadius(20)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(milestoneManager.milestones) { milestone in
                                            MilestoneCard(milestone: milestone)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        // Collapsed Milestone Section
                        Button {
                            showingAddMilestone = true
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.purple)
                                
                                Text("Track a Milestone")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.purple)
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Thought.ThoughtCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedFilter == category
                                ) {
                                    if selectedFilter == category {
                                        selectedFilter = nil
                                    } else {
                                        selectedFilter = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Thoughts List
                    if thoughtManager.isLoading {
                        ProgressView()
                            .padding()
                    } else if filteredThoughts.isEmpty {
                        VStack(spacing: 24) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 80))
                                .foregroundColor(.purple.opacity(0.6))
                            
                            VStack(spacing: 8) {
                                Text(thoughtManager.thoughts.isEmpty ? "No Thoughts Yet" : "No Matching Thoughts")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(thoughtManager.thoughts.isEmpty ? "Tap the Create tab to write your first thought" : "Try adjusting your filters")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredThoughts) { thought in
                                ThoughtCard(thought: thought)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await thoughtManager.fetchUserThoughts()
            await milestoneManager.fetchMilestones()
            await moodManager.checkTodayMood()
        }
        .refreshable {
            await thoughtManager.fetchUserThoughts()
            await milestoneManager.fetchMilestones()
            await moodManager.checkTodayMood()
        }
        .sheet(isPresented: $showingAddMilestone) {
            AddMilestoneSheet()
        }
        .sheet(isPresented: $showingMoodCheckIn) {
            DailyMoodCheckIn()
        }
        .sheet(isPresented: $showingCreateThought) {
            CreateThoughtView(isDismissable: true)
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingCreateThought = true
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.purple)
                    .clipShape(Circle())
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
    
    var filteredThoughts: [Thought] {
        if let filter = selectedFilter {
            return thoughtManager.thoughts.filter { $0.category == filter }
        }
        return thoughtManager.thoughts
    }
}

struct CategoryChip: View {
    let category: Thought.ThoughtCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.emoji)
                    .font(.body)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(isSelected ? Color.purple : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "paperplane")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No thoughts yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first thought to begin your healing journey")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
        .environmentObject(ThoughtManager())
        .environmentObject(MilestoneManager())
        .environmentObject(MoodManager())
}
