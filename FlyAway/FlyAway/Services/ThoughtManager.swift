import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class ThoughtManager: ObservableObject {
    @Published var thoughts: [Thought] = []
    @Published var savedThoughts: [Thought] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func createThought(
        content: String,
        isPublic: Bool,
        category: Thought.ThoughtCategory,
        sendToEther: Bool,
        keepForDays: Int?
    ) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                self.errorMessage = "User not authenticated"
            }
            print("❌ Error: User not authenticated")
            return
        }
        
        // Use displayName if available, otherwise use email
        let userName = Auth.auth().currentUser?.displayName ?? Auth.auth().currentUser?.email ?? "Anonymous"
        
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
            content: content,
            isPublic: isPublic,
            createdAt: Date(),
            expiresAt: expiresAt,
            isVoice: false,
            audioURL: nil,
            tags: [],
            saveCount: 0,
            category: category
        )
        
        do {
            let docRef = try db.collection("thoughts").addDocument(from: thought)
            print("✅ Thought saved with ID: \(docRef.documentID)")
            
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
        
        let savedThought = SavedThought(
            thoughtId: thoughtId,
            userId: userId,
            savedAt: Date()
        )
        
        do {
            try db.collection("savedThoughts").addDocument(from: savedThought)
            
            // Increment save count
            if let thoughtId = thought.id {
                try await db.collection("thoughts").document(thoughtId)
                    .updateData(["saveCount": FieldValue.increment(Int64(1))])
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteThought(_ thought: Thought) async {
        guard let thoughtId = thought.id else { return }
        
        do {
            try await db.collection("thoughts").document(thoughtId).delete()
            await fetchUserThoughts()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
