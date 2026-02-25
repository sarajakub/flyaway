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

    // Explicit CodingKeys — `id` is intentionally excluded.
    // @DocumentID reads the document ID from Firestore metadata (decoder userInfo),
    // not from a field in the document data, so it must NOT go through the keyed container.
    enum CodingKeys: String, CodingKey {
        case userId, recipientName, content, createdAt, isRead, isVoice, audioURL
    }

    // Memberwise init used when creating new messages in code
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

    // Custom decoder so old Firestore documents that predate isVoice/audioURL
    // still decode successfully instead of returning nil from compactMap.
    init(from decoder: Decoder) throws {
        // Let @DocumentID extract the document ID from Firestore's decoder userInfo
        _id = try DocumentID(from: decoder)

        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId        = try c.decode(String.self,          forKey: .userId)
        recipientName = try c.decode(String.self,          forKey: .recipientName)
        content       = try c.decode(String.self,          forKey: .content)
        createdAt     = try c.decode(Date.self,            forKey: .createdAt)
        isRead        = try c.decodeIfPresent(Bool.self,   forKey: .isRead)   ?? false
        isVoice       = try c.decodeIfPresent(Bool.self,   forKey: .isVoice)  ?? false
        audioURL      = try c.decodeIfPresent(String.self, forKey: .audioURL)
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
