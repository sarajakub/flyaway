import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var recipientName: String
    var content: String
    var createdAt: Date
    var isRead: Bool
    
    init(id: String? = nil, userId: String, recipientName: String, content: String, createdAt: Date, isRead: Bool = false) {
        self.id = id
        self.userId = userId
        self.recipientName = recipientName
        self.content = content
        self.createdAt = createdAt
        self.isRead = isRead
    }
}

struct MessageThread: Identifiable {
    let id = UUID()
    let recipientName: String
    var messages: [Message]
    var lastMessageDate: Date {
        messages.last?.createdAt ?? Date()
    }
}
