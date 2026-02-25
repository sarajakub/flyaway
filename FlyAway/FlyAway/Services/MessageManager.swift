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

        let voiceRef = Storage.storage().reference()
            .child("voiceMessages/\(userId)/\(UUID().uuidString).m4a")
        let metadata = StorageMetadata()
        metadata.contentType = "audio/mp4"

        // Step 1: Upload — use callback API wrapped in a continuation.
        // putFileAsync has a known bug in some Firebase SDK versions where it
        // internally calls getMetadata() after the upload completes, causing a
        // spurious "Object does not exist" error even when the upload succeeded.
        // The callback-based putFile avoids this entirely.
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                voiceRef.putFile(from: localURL, metadata: metadata) { _, error in
                    if let error = error {
                        // Log the raw Storage error code to distinguish:
                        //   objectNotFound (404)  → bucket disabled / billing required (Blaze plan needed after Feb 3 2026) OR bad Security Rules
                        //   unauthorized   (403)  → Security Rules are blocking write
                        //   unauthenticated(401)  → user not signed in at Storage level
                        //   bucketNotFound        → bucket not yet created in console
                        let nsErr = error as NSError
                        print("❌ Storage upload failed — code: \(nsErr.code), domain: \(nsErr.domain), description: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Voice uploaded to: \(voiceRef.fullPath)")
                        continuation.resume()
                    }
                }
            }
        } catch {
            await MainActor.run { self.errorMessage = "Upload failed: \(error.localizedDescription)" }
            return
        }

        // Step 2: Save the Firestore message record using the storage path.
        let storagePath = voiceRef.fullPath
        do {
            let message = Message(
                userId: userId,
                recipientName: recipientName,
                content: "🎤 Voice message",
                createdAt: Date(),
                isRead: false,
                isVoice: true,
                audioURL: storagePath
            )
            _ = try db.collection("messages").addDocument(from: message)
            print("✅ Voice message saved to Firestore")
        } catch {
            print("❌ Firestore save failed: \(error.localizedDescription)")
            await MainActor.run { self.errorMessage = "Could not save message: \(error.localizedDescription)" }
            return
        }

        await fetchMessages()
        try? FileManager.default.removeItem(at: localURL)
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

            // Delete Firestore docs first — they are the source of truth.
            // Storage cleanup is best-effort after; an orphaned .m4a is a minor
            // cost issue, while a dangling Firestore record pointing to a deleted
            // Storage file causes a broken UI for the user.
            for document in snapshot.documents {
                try await document.reference.delete()
            }

            // Clean up Storage files (best effort — don't throw on failure)
            for document in snapshot.documents {
                if let msg = try? document.data(as: Message.self),
                   msg.isVoice,
                   let path = msg.audioURL,
                   !path.hasPrefix("https://") {
                    try? await Storage.storage().reference(withPath: path).delete()
                    print("🗑 Deleted Storage file: \(path)")
                }
            }

            await fetchMessages()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func deleteMessage(_ message: Message) async {
        guard let docId = message.id else { return }

        // Delete Firestore record first, then Storage (same reasoning as deleteThread)
        do {
            try await db.collection("messages").document(docId).delete()
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
            return
        }

        if message.isVoice, let path = message.audioURL, !path.hasPrefix("https://") {
            try? await Storage.storage().reference(withPath: path).delete()
            print("🗑 Deleted Storage file: \(path)")
        }

        await fetchMessages()
    }
}
