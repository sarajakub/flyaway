import Foundation
import FirebaseFirestore

struct Thought: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var userName: String
    var content: String
    var isPublic: Bool
    var createdAt: Date
    var expiresAt: Date?
    var isVoice: Bool
    var audioURL: String?
    var tags: [String]
    var saveCount: Int
    var category: ThoughtCategory
    var reactionCounts: [String: Int]

    enum CodingKeys: String, CodingKey {
        case userId, userName, content, isPublic, createdAt, expiresAt
        case isVoice, audioURL, tags, saveCount, category, reactionCounts
        // id excluded — @DocumentID reads from Firestore decoder userInfo
    }

    init(from decoder: Decoder) throws {
        _id = try DocumentID(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId        = try c.decode(String.self,  forKey: .userId)
        userName      = try c.decode(String.self,  forKey: .userName)
        content       = try c.decode(String.self,  forKey: .content)
        isPublic      = try c.decode(Bool.self,    forKey: .isPublic)
        createdAt     = try c.decode(Date.self,    forKey: .createdAt)
        expiresAt     = try c.decodeIfPresent(Date.self,   forKey: .expiresAt)
        isVoice       = try c.decodeIfPresent(Bool.self,   forKey: .isVoice)       ?? false
        audioURL      = try c.decodeIfPresent(String.self, forKey: .audioURL)
        tags          = try c.decodeIfPresent([String].self,        forKey: .tags)          ?? []
        saveCount     = try c.decodeIfPresent(Int.self,             forKey: .saveCount)     ?? 0
        reactionCounts = try c.decodeIfPresent([String: Int].self,  forKey: .reactionCounts) ?? [:]
        category      = try c.decodeIfPresent(ThoughtCategory.self, forKey: .category)     ?? .reflection
    }

    // Memberwise init used when creating new thoughts in code
    init(
        userId: String, userName: String, content: String,
        isPublic: Bool, createdAt: Date, expiresAt: Date?,
        isVoice: Bool, audioURL: String?, tags: [String],
        saveCount: Int, category: ThoughtCategory, reactionCounts: [String: Int]
    ) {
        self.userId = userId; self.userName = userName; self.content = content
        self.isPublic = isPublic; self.createdAt = createdAt; self.expiresAt = expiresAt
        self.isVoice = isVoice; self.audioURL = audioURL; self.tags = tags
        self.saveCount = saveCount; self.category = category; self.reactionCounts = reactionCounts
    }
    
    enum ThoughtCategory: String, Codable, CaseIterable {
        case breakup = "Breakup"
        case grief = "Grief"
        case anxiety = "Anxiety"
        case healing = "Healing"
        case gratitude = "Gratitude"
        case reflection = "Reflection"
        case other = "Other"
        
        var emoji: String {
            switch self {
            case .breakup: return "💔"
            case .grief: return "🕊️"
            case .anxiety: return "🌊"
            case .healing: return "🌱"
            case .gratitude: return "✨"
            case .reflection: return "🤔"
            case .other: return "💭"
            }
        }
    }
}

struct SavedThought: Identifiable, Codable {
    @DocumentID var id: String?
    var thoughtId: String
    var userId: String
    var savedAt: Date
}
