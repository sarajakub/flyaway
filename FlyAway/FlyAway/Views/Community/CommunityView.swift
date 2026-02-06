import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var thoughtManager: ThoughtManager
    @State private var selectedCategory: Thought.ThoughtCategory?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search thoughts...", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: { selectedCategory = nil }) {
                            Text("All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == nil ? Color.purple : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == nil ? .white : .primary)
                                .cornerRadius(20)
                        }
                        
                        ForEach(Thought.ThoughtCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredThoughts) { thought in
                            CommunityThoughtCard(thought: thought)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Community")
        }
        .task {
            await thoughtManager.fetchPublicThoughts()
        }
        .refreshable {
            await thoughtManager.fetchPublicThoughts()
        }
    }
    
    var filteredThoughts: [Thought] {
        var thoughts = thoughtManager.thoughts
        
        if let category = selectedCategory {
            thoughts = thoughts.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            thoughts = thoughts.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
        
        return thoughts
    }
}

struct CommunityThoughtCard: View {
    let thought: Thought
    @EnvironmentObject var thoughtManager: ThoughtManager
    @State private var isSaved = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(thought.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        Text(thought.category.emoji)
                        Text(thought.category.rawValue)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: saveThought) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(.purple)
                        .font(.title3)
                }
            }
            
            Text(thought.content)
                .font(.body)
                .lineLimit(nil)
            
            HStack {
                Text(thought.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(thought.saveCount)", systemImage: "bookmark.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func saveThought() {
        Task {
            await thoughtManager.saveThought(thought)
            isSaved = true
        }
    }
}

#Preview {
    CommunityView()
        .environmentObject(ThoughtManager())
}
