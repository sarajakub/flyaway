import Foundation
import FirebaseFirestore

struct Reaction: Codable, Identifiable {
    @DocumentID var id: String?
    let thoughtId: String
    let userId: String
    let type: ReactionType
    let createdAt: Date
    
    enum ReactionType: String, Codable, CaseIterable {
        case heart = "💜"        // Empathy/support
        case sparkle = "🌟"      // Inspiring/uplifting
        case peace = "🕊️"        // Peaceful/calming
        case growth = "🌱"       // Growth/healing
        
        var label: String {
            switch self {
            case .heart: return "Support"
            case .sparkle: return "Inspiring"
            case .peace: return "Peaceful"
            case .growth: return "Growth"
            }
        }
    }
    
    init(thoughtId: String, userId: String, type: ReactionType) {
        self.thoughtId = thoughtId
        self.userId = userId
        self.type = type
        self.createdAt = Date()
    }
}
