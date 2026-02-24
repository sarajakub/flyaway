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
    var reactionCounts: [String: Int] // "heart": 5, "sparkle": 3, etc.
    
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
