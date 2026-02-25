import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class MoodManager: ObservableObject {
    @Published var moodEntries: [MoodEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var todayMood: MoodEntry?
    
    private let db = Firestore.firestore()
    
    func checkTodayMood() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        do {
            // Limit to 10 most recent entries — at one per day max this is
            // always enough to find today's without loading the entire history.
            // Avoids a composite index (userId + createdAt) by filtering client-side
            // on the small bounded result set.
            let snapshot = try await db.collection("moodEntries")
                .whereField("userId", isEqualTo: userId)
                .limit(to: 10)
                .getDocuments()

            await MainActor.run {
                let entries = snapshot.documents.compactMap { doc -> MoodEntry? in
                    try? doc.data(as: MoodEntry.self)
                }
                .filter { $0.createdAt >= startOfDay && $0.createdAt < endOfDay }
                .sorted { $0.createdAt > $1.createdAt }

                self.todayMood = entries.first
            }
        } catch {
            print("❌ Error checking today's mood: \(error.localizedDescription)")
        }
    }
    
    func saveMood(mood: Int, note: String?) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            await MainActor.run { self.errorMessage = "User not authenticated" }
            return
        }
        // Validate range — guards against any accidental UI bugs sending out-of-range values
        guard (1...5).contains(mood) else {
            await MainActor.run { self.errorMessage = "Invalid mood value" }
            return
        }
        
        let entry = MoodEntry(
            userId: userId,
            mood: mood,
            note: note,
            createdAt: Date()
        )
        
        do {
            let docRef = try db.collection("moodEntries").addDocument(from: entry)
            print("✅ Mood saved with ID: \(docRef.documentID)")
            
            await checkTodayMood()
            await fetchMoodEntries()
        } catch {
            print("❌ Error saving mood: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func fetchMoodEntries(days: Int = 30) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            // Get all user's entries and filter client-side to avoid composite index
            let snapshot = try await db.collection("moodEntries")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let entries = snapshot.documents.compactMap { doc -> MoodEntry? in
                try? doc.data(as: MoodEntry.self)
            }
            .filter { $0.createdAt >= startDate }
            .sorted { $0.createdAt < $1.createdAt } // Ascending for graph
            
            await MainActor.run {
                self.moodEntries = entries
                self.isLoading = false
            }
        } catch {
            print("❌ Error fetching mood entries: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
