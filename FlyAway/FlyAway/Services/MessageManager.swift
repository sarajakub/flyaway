import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

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
    
    // MARK: - Voice Messages

    /// Uploads the local .m4a at `localURL` to Firebase Storage, then saves a voice message to Firestore.
    func sendVoiceMessage(to recipientName: String, localURL: URL) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            await MainActor.run { self.errorMessage = "User not authenticated" }
            return
        }

        // Guard against empty/corrupt recordings (common on Simulator)
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: localURL.path)[.size] as? Int) ?? 0
        guard fileSize > 0 else {
            print("❌ Voice message file is empty (\(localURL.lastPathComponent)) — skipping upload")
            await MainActor.run { self.errorMessage = "Recording was empty. Please try again." }
            return
        }
        print("🎙 Uploading voice message: \(localURL.lastPathComponent) (\(fileSize) bytes)")

        do {
            // Upload directly from file URL — more reliable than loading into Data
            let voiceRef = Storage.storage().reference()
                .child("voiceMessages/\(userId)/\(UUID().uuidString).m4a")
            let metadata = StorageMetadata()
            metadata.contentType = "audio/mp4"
            _ = try await voiceRef.putFileAsync(from: localURL, metadata: metadata)
            let downloadURL = try await voiceRef.downloadURL()
            print("✅ Voice uploaded to: \(downloadURL)")

            // Save Firestore message record
            let message = Message(
                userId: userId,
                recipientName: recipientName,
                content: "🎤 Voice message",
                createdAt: Date(),
                isRead: false,
                isVoice: true,
                audioURL: downloadURL.absoluteString
            )
            _ = try db.collection("messages").addDocument(from: message)
            print("✅ Voice message saved")
            await fetchMessages()

            // Clean up temp file
            try? FileManager.default.removeItem(at: localURL)
        } catch {
            print("❌ Error sending voice message: \(error.localizedDescription)")
            await MainActor.run { self.errorMessage = error.localizedDescription }
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
