import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var thoughtManager: ThoughtManager
    @State private var selectedCategory: Thought.ThoughtCategory?
    @State private var sortOption: CommunitySortOption = .recent
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    enum CommunitySortOption: String, CaseIterable {
        case recent = "Recent"
        case mostSaved = "Most Saved"
        case forYou = "For You"
        
        var icon: String {
            switch self {
            case .recent: return "clock"
            case .mostSaved: return "bookmark.fill"
            case .forYou: return "sparkles"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Community Header - Different from Home
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Community")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("You're not alone in this journey")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Community indicator
                        Image(systemName: "heart.circle.fill")
                            .font(.title)
                            .foregroundColor(.purple.opacity(0.7))
                    }
                }
                .padding()
                .background(Color.purple.opacity(0.05))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search thoughts...", text: $searchText)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            isSearchFocused = false
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            isSearchFocused = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: { selectedCategory = nil }) {
                            Text("All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(selectedCategory == nil ? Color.purple : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == nil ? .white : .primary)
                                .cornerRadius(20)
                        }
                        
                        ForEach(Thought.ThoughtCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
                .padding(.bottom, 12)
                
                // Sort Options
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sort by:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading)
                        
                        Spacer()
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(CommunitySortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: option.icon)
                                            .font(.caption)
                                        Text(option.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(sortOption == option ? Color.purple : Color(.systemGray6))
                                    .foregroundColor(sortOption == option ? .white : .primary)
                                    .cornerRadius(18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(sortOption == option ? Color.purple : Color.clear, lineWidth: 2)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 8)
                
                if thoughtManager.isLoading {
                    VStack {
                        ProgressView()
                            .padding()
                        Text("Loading community thoughts...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if filteredThoughts.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "person.3")
                            .font(.system(size: 80))
                            .foregroundColor(.purple.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text(thoughtManager.thoughts.isEmpty ? "No Community Thoughts Yet" : "No Matching Thoughts")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(thoughtManager.thoughts.isEmpty ? "Be the first to share a public thought!" : "Try adjusting your search or filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredThoughts) { thought in
                                CommunityThoughtCard(thought: thought)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isSearchFocused = false
                    }
                    .foregroundColor(.purple)
                }
            }
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
        
        // Apply category filter
        if let category = selectedCategory {
            thoughts = thoughts.filter { $0.category == category }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            thoughts = thoughts.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply sorting
        switch sortOption {
        case .recent:
            return thoughts.sorted { $0.createdAt > $1.createdAt }
        case .mostSaved:
            return thoughts.sorted { $0.saveCount > $1.saveCount }
        case .forYou:
            // Get user's active categories from their own thoughts
            let userCategories = Set(thoughtManager.thoughts
                .filter { $0.userId == thoughtManager.thoughts.first?.userId }
                .map { $0.category })
            
            // Prioritize thoughts in user's categories, then sort by recent
            return thoughts.sorted { thought1, thought2 in
                let cat1Match = userCategories.contains(thought1.category)
                let cat2Match = userCategories.contains(thought2.category)
                
                if cat1Match && !cat2Match {
                    return true
                } else if !cat1Match && cat2Match {
                    return false
                } else {
                    return thought1.createdAt > thought2.createdAt
                }
            }
        }
    }
}

struct CommunityThoughtCard: View {
    let thought: Thought
    @EnvironmentObject var thoughtManager: ThoughtManager
    @State private var isSaved = false
    @State private var isCheckingSaved = true
    @State private var userReactions: Set<Reaction.ReactionType> = []
    
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
                
                Button(action: toggleSave) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isSaved ? .purple : .gray)
                        .font(.title3)
                }
                .opacity(isCheckingSaved ? 0.5 : 1.0)
                .disabled(isCheckingSaved)
            }
            
            Text(thought.content)
                .font(.body)
                .lineLimit(nil)
                .padding(.bottom, 12)
            
            // Reactions - Twitter style
            HStack(spacing: 20) {
                ForEach(Reaction.ReactionType.allCases, id: \.self) { type in
                    Button {
                        toggleReaction(type)
                    } label: {
                        HStack(spacing: 6) {
                            Text(type.rawValue)
                                .font(.body)
                            
                            if let count = thought.reactionCounts[type.rawValue], count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(userReactions.contains(type) ? .purple : .secondary)
                            }
                        }
                        .opacity(userReactions.contains(type) ? 1.0 : 0.6)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(userReactions.contains(type) ? Color.purple.opacity(0.1) : Color.clear)
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 4)
            
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
        .task {
            await checkIfSaved()
            await loadUserReactions()
        }
    }
    
    private func loadUserReactions() async {
        userReactions = await thoughtManager.getUserReactions(thought)
    }
    
    private func toggleReaction(_ type: Reaction.ReactionType) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        Task {
            if userReactions.contains(type) {
                await thoughtManager.removeReaction(thought, type: type)
                userReactions.remove(type)
            } else {
                await thoughtManager.addReaction(thought, type: type)
                userReactions.insert(type)
            }
        }
    }
    
    private func checkIfSaved() async {
        isSaved = await thoughtManager.isThoughtSaved(thought)
        isCheckingSaved = false
    }
    
    private func toggleSave() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        Task {
            if isSaved {
                await thoughtManager.unsaveThought(thought)
                isSaved = false
            } else {
                await thoughtManager.saveThought(thought)
                isSaved = true
            }
        }
    }
}

#Preview {
    CommunityView()
        .environmentObject(ThoughtManager())
}
