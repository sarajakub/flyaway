import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class MessageManager: ObservableObject {
    @Published var messageThreads: [MessageThread] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func sendMessage(to recipientName: String, content: String) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                self.errorMessage = "User not authenticated"
            }
            return
        }
        
        let message = Message(
            userId: userId,
            recipientName: recipientName,
            content: content,
            createdAt: Date(),
            isRead: false
        )
        
        do {
            let docRef = try db.collection("messages").addDocument(from: message)
            print("✅ Message saved with ID: \(docRef.documentID)")
            await fetchMessages()
        } catch {
            print("❌ Error saving message: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func fetchMessages() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let snapshot = try await db.collection("messages")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let messages = snapshot.documents.compactMap { doc -> Message? in
                try? doc.data(as: Message.self)
            }
            
            // Sort in memory to avoid index requirements
            let sortedMessages = messages.sorted { $0.createdAt < $1.createdAt }
            
            // Group messages by recipient
            var threadsDict: [String: [Message]] = [:]
            for message in sortedMessages {
                threadsDict[message.recipientName, default: []].append(message)
            }
            
            let threads = threadsDict.map { recipientName, messages in
                MessageThread(recipientName: recipientName, messages: messages)
            }.sorted { $0.lastMessageDate > $1.lastMessageDate }
            
            await MainActor.run {
                self.messageThreads = threads
                self.isLoading = false
            }
        } catch {
            print("❌ Error fetching messages: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func deleteThread(recipientName: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("messages")
                .whereField("userId", isEqualTo: userId)
                .whereField("recipientName", isEqualTo: recipientName)
                .getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
            await fetchMessages()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
