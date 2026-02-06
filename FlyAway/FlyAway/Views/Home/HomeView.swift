import SwiftUI

struct HomeView: View {
    @EnvironmentObject var thoughtManager: ThoughtManager
    @State private var selectedFilter: Thought.ThoughtCategory?
    
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
                    } else if thoughtManager.thoughts.isEmpty {
                        EmptyStateView()
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
            HStack(spacing: 4) {
                Text(category.emoji)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
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
}
