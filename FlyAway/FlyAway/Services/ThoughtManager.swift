import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class ThoughtManager: ObservableObject {
    @Published var thoughts: [Thought] = []
    @Published var savedThoughts: [Thought] = []
    @Published var thoughtActivities: [ThoughtActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func createThought(
        content: String,
        isPublic: Bool,
        category: Thought.ThoughtCategory,
        sendToEther: Bool,
        keepForDays: Int?,
        postAsAnonymous: Bool = true
    ) async {
        // Clear any stale error from previous operations before starting
        await MainActor.run { self.errorMessage = nil }

        guard let userId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                self.errorMessage = "User not authenticated"
            }
            print("❌ Error: User not authenticated")
            return
        }
        
        // Validate content before hitting Firestore
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run { self.errorMessage = "Thought cannot be empty" }
            return
        }
        let safeContent = String(trimmed.prefix(2000)) // hard cap at 2000 chars

        let userName: String
        if postAsAnonymous {
            userName = "Anonymous"
        } else {
            userName = Auth.auth().currentUser?.displayName ?? "User"
        }
        
        let expiresAt: Date?
        if sendToEther {
            expiresAt = Date().addingTimeInterval(60) // Expire in 1 minute
        } else if let days = keepForDays {
            expiresAt = Date().addingTimeInterval(TimeInterval(days * 86400))
        } else {
            expiresAt = nil // Keep forever
        }
        
        let thought = Thought(
            userId: userId,
            userName: userName,
            content: safeContent,
            isPublic: isPublic,
            createdAt: Date(),
            expiresAt: expiresAt,
            isVoice: false,
            audioURL: nil,
            tags: [],
            saveCount: 0,
            category: category,
            reactionCounts: [:]
        )
        
        do {
            let docRef = try db.collection("thoughts").addDocument(from: thought)
            print("✅ Thought saved with ID: \(docRef.documentID)")

            // Schedule expiry notification when thought has a finite lifetime
            if let expiresAt = thought.expiresAt {
                NotificationManager.shared.scheduleExpiryNotification(
                    thoughtId: docRef.documentID,
                    content: thought.content,
                    expiresAt: expiresAt
                )
            }

            // Log activity
            let activity = ThoughtActivity(
                userId: userId,
                thoughtId: docRef.documentID,
                activityType: .created,
                category: category,
                createdAt: Date(),
                sentToEther: sendToEther
            )
            try? db.collection("thoughtActivities").addDocument(from: activity)
            
            if !sendToEther {
                await fetchUserThoughts()
            }
        } catch {
            print("❌ Error saving thought: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func fetchPublicThoughts() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let snapshot = try await db.collection("thoughts")
                .whereField("isPublic", isEqualTo: true)
                .getDocuments()
            
            let thoughts = snapshot.documents.compactMap { doc -> Thought? in
                try? doc.data(as: Thought.self)
            }
            
            // Sort in memory instead of using Firestore ordering (avoids index requirement)
            let filteredAndSorted = thoughts
                .filter { thought in
                    if let expiresAt = thought.expiresAt {
                        return expiresAt > Date()
                    }
                    return true
                }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(50) // Limit to 50 most recent
            
            await MainActor.run {
                self.thoughts = Array(filteredAndSorted)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func fetchUserThoughts() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("thoughts")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let thoughts = snapshot.documents.compactMap { doc -> Thought? in
                try? doc.data(as: Thought.self)
            }
            
            // Sort in memory instead of using Firestore ordering (avoids index requirement)
            let sortedThoughts = thoughts
                .filter { thought in
                    if let expiresAt = thought.expiresAt {
                        return expiresAt > Date()
                    }
                    return true
                }
                .sorted { $0.createdAt > $1.createdAt }
            
            await MainActor.run {
                self.thoughts = sortedThoughts
            }
        } catch {
            print("❌ Error fetching user thoughts: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func saveThought(_ thought: Thought) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let thoughtId = thought.id else { return }
        
        // Check if already saved
        do {
            let existingSnapshot = try await db.collection("savedThoughts")
                .whereField("userId", isEqualTo: userId)
                .whereField("thoughtId", isEqualTo: thoughtId)
                .getDocuments()
            
            if !existingSnapshot.documents.isEmpty {
                print("⚠️ Thought already saved")
                return
            }
        } catch {
            print("❌ Error checking for duplicate: \(error.localizedDescription)")
        }
        
        let savedThought = SavedThought(
            thoughtId: thoughtId,
            userId: userId,
            savedAt: Date()
        )
        
        do {
            try db.collection("savedThoughts").addDocument(from: savedThought)
            print("✅ Thought saved to savedThoughts collection")
            
            // Increment save count
            if let thoughtId = thought.id {
                try await db.collection("thoughts").document(thoughtId)
                    .updateData(["saveCount": FieldValue.increment(Int64(1))])
            }
            
            // Refresh saved thoughts
            await fetchSavedThoughts()
        } catch {
            print("❌ Error saving thought: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func unsaveThought(_ thought: Thought) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let thoughtId = thought.id else { return }
        
        do {
            let snapshot = try await db.collection("savedThoughts")
                .whereField("userId", isEqualTo: userId)
                .whereField("thoughtId", isEqualTo: thoughtId)
                .getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
            print("✅ Thought unsaved")
            
            // Decrement save count
            try await db.collection("thoughts").document(thoughtId)
                .updateData(["saveCount": FieldValue.increment(Int64(-1))])
            
            // Refresh saved thoughts
            await fetchSavedThoughts()
        } catch {
            print("❌ Error unsaving thought: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func isThoughtSaved(_ thought: Thought) async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid,
              let thoughtId = thought.id else { return false }
        
        do {
            let snapshot = try await db.collection("savedThoughts")
                .whereField("userId", isEqualTo: userId)
                .whereField("thoughtId", isEqualTo: thoughtId)
                .getDocuments()
            
            return !snapshot.documents.isEmpty
        } catch {
            return false
        }
    }
    
    private func cleanupDuplicateSaves(userId: String, savedSnapshot: QuerySnapshot) async {
        // Group documents by thoughtId
        var thoughtIdToDocuments: [String: [QueryDocumentSnapshot]] = [:]
        
        for doc in savedSnapshot.documents {
            if let savedThought = try? doc.data(as: SavedThought.self) {
                if thoughtIdToDocuments[savedThought.thoughtId] == nil {
                    thoughtIdToDocuments[savedThought.thoughtId] = []
                }
                thoughtIdToDocuments[savedThought.thoughtId]?.append(doc)
            }
        }
        
        // Delete duplicates (keep the first one, delete the rest)
        for (thoughtId, documents) in thoughtIdToDocuments {
            if documents.count > 1 {
                print("🗑️ Removing \(documents.count - 1) duplicate(s) for thought \(thoughtId)")
                for doc in documents.dropFirst() {
                    do {
                        try await doc.reference.delete()
                    } catch {
                        print("❌ Error deleting duplicate: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func fetchSavedThoughts() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Get saved thought references
            let savedSnapshot = try await db.collection("savedThoughts")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let savedThoughtIds = savedSnapshot.documents.compactMap { doc -> String? in
                try? doc.data(as: SavedThought.self).thoughtId
            }
            
            // Clean up duplicates if found
            let uniqueThoughtIds = Array(Set(savedThoughtIds))
            if savedThoughtIds.count > uniqueThoughtIds.count {
                print("🧹 Found duplicates, cleaning up...")
                await cleanupDuplicateSaves(userId: userId, savedSnapshot: savedSnapshot)
            }
            
            print("📚 Found \(savedThoughtIds.count) saved thought IDs (\(uniqueThoughtIds.count) unique)")
            
            // Fetch the actual thoughts
            var thoughts: [Thought] = []
            for thoughtId in uniqueThoughtIds {
                do {
                    let thoughtDoc = try await db.collection("thoughts").document(thoughtId).getDocument()
                    if let thought = try? thoughtDoc.data(as: Thought.self) {
                        thoughts.append(thought)
                    }
                } catch {
                    print("❌ Error fetching thought \(thoughtId): \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                self.savedThoughts = thoughts.sorted { $0.createdAt > $1.createdAt }
                    .filter { thought in
                        // Filter out expired thoughts
                        if let expiresAt = thought.expiresAt {
                            return expiresAt > Date()
                        }
                        return true
                    }
                print("✅ Loaded \(self.savedThoughts.count) saved thoughts (filtered expired)")
            }
        } catch {
            print("❌ Error fetching saved thoughts: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteThought(_ thought: Thought) async {
        guard let thoughtId = thought.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Log deletion activity
            let activity = ThoughtActivity(
                userId: userId,
                thoughtId: thoughtId,
                activityType: .deleted,
                category: thought.category,
                createdAt: Date(),
                sentToEther: false
            )
            try? db.collection("thoughtActivities").addDocument(from: activity)
            
            try await db.collection("thoughts").document(thoughtId).delete()

            // Cancel any pending expiry notification for this thought
            NotificationManager.shared.cancelExpiryNotification(thoughtId: thoughtId)

            await fetchUserThoughts()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func fetchThoughtActivities() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("thoughtActivities")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let activities = snapshot.documents.compactMap { doc -> ThoughtActivity? in
                try? doc.data(as: ThoughtActivity.self)
            }
            .sorted { $0.createdAt > $1.createdAt } // Sort in memory instead
            
            await MainActor.run {
                self.thoughtActivities = activities
            }
        } catch {
            print("❌ Error fetching thought activities: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reactions
    
    func addReaction(_ thought: Thought, type: Reaction.ReactionType) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let thoughtId = thought.id else { return }
        
        do {
            // Check if user already reacted with this type
            let existing = try await db.collection("reactions")
                .whereField("thoughtId", isEqualTo: thoughtId)
                .whereField("userId", isEqualTo: userId)
                .whereField("type", isEqualTo: type.rawValue)
                .getDocuments()
            
            if !existing.documents.isEmpty {
                print("⚠️ User already reacted with this type")
                return
            }
            
            // Add reaction
            let reaction = Reaction(thoughtId: thoughtId, userId: userId, type: type)
            try db.collection("reactions").addDocument(from: reaction)
            
            // Update reaction count on thought
            let reactionKey = "reactionCounts.\(type.rawValue)"
            try await db.collection("thoughts").document(thoughtId)
                .updateData([reactionKey: FieldValue.increment(Int64(1))])
            
            print("✅ Reaction added: \(type.label)")
            
            await fetchPublicThoughts()
        } catch {
            print("❌ Error adding reaction: \(error.localizedDescription)")
        }
    }
    
    func removeReaction(_ thought: Thought, type: Reaction.ReactionType) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let thoughtId = thought.id else { return }
        
        do {
            let snapshot = try await db.collection("reactions")
                .whereField("thoughtId", isEqualTo: thoughtId)
                .whereField("userId", isEqualTo: userId)
                .whereField("type", isEqualTo: type.rawValue)
                .getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
            // Update reaction count on thought
            let reactionKey = "reactionCounts.\(type.rawValue)"
            try await db.collection("thoughts").document(thoughtId)
                .updateData([reactionKey: FieldValue.increment(Int64(-1))])
            
            print("✅ Reaction removed")
            
            await fetchPublicThoughts()
        } catch {
            print("❌ Error removing reaction: \(error.localizedDescription)")
        }
    }
    
    func getUserReactions(_ thought: Thought) async -> Set<Reaction.ReactionType> {
        guard let userId = Auth.auth().currentUser?.uid,
              let thoughtId = thought.id else { return [] }
        
        do {
            let snapshot = try await db.collection("reactions")
                .whereField("thoughtId", isEqualTo: thoughtId)
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let reactions = snapshot.documents.compactMap { doc -> Reaction.ReactionType? in
                if let reaction = try? doc.data(as: Reaction.self) {
                    return reaction.type
                }
                return nil
            }
            
            return Set(reactions)
        } catch {
            return []
        }
    }
}
