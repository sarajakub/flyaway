import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class MilestoneManager: ObservableObject {
    @Published var milestones: [Milestone] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func createMilestone(title: String, eventDate: Date) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let milestone = Milestone(
            userId: userId,
            title: title,
            eventDate: eventDate,
            createdAt: Date()
        )
        
        do {
            try db.collection("milestones").addDocument(from: milestone)
            print("✅ Milestone created: \(title)")
            await fetchMilestones()
        } catch {
            print("❌ Error creating milestone: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func fetchMilestones() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let snapshot = try await db.collection("milestones")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let milestones = snapshot.documents.compactMap { doc -> Milestone? in
                try? doc.data(as: Milestone.self)
            }
            
            await MainActor.run {
                self.milestones = milestones.sorted { $0.eventDate > $1.eventDate }
                self.isLoading = false
            }
        } catch {
            print("❌ Error fetching milestones: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func updateMilestone(_ milestone: Milestone) async {
        guard let milestoneId = milestone.id else { return }
        
        do {
            try db.collection("milestones").document(milestoneId).setData(from: milestone)
            await fetchMilestones()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteMilestone(_ milestone: Milestone) async {
        guard let milestoneId = milestone.id else { return }
        
        do {
            try await db.collection("milestones").document(milestoneId).delete()
            await fetchMilestones()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
