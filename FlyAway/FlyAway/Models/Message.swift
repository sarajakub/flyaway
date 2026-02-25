import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var recipientName: String
    var content: String
    var createdAt: Date
    var isRead: Bool
    var isVoice: Bool
    var audioURL: String?

    init(id: String? = nil,
         userId: String,
         recipientName: String,
         content: String,
         createdAt: Date,
         isRead: Bool = false,
         isVoice: Bool = false,
         audioURL: String? = nil) {
        self.id = id
        self.userId = userId
        self.recipientName = recipientName
        self.content = content
        self.createdAt = createdAt
        self.isRead = isRead
        self.isVoice = isVoice
        self.audioURL = audioURL
    }
}

struct MessageThread: Identifiable, Hashable {
    let id = UUID()
    let recipientName: String
    var messages: [Message]
    var lastMessageDate: Date {
        messages.last?.createdAt ?? Date()
    }

    // Hash and equality on id only — avoids needing Message: Hashable
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: MessageThread, rhs: MessageThread) -> Bool { lhs.id == rhs.id }
}
