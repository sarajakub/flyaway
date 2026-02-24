import Foundation
import FirebaseFirestore

struct ThoughtActivity: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var thoughtId: String?
    var activityType: ActivityType
    var category: Thought.ThoughtCategory
    var createdAt: Date
    var sentToEther: Bool
    
    enum ActivityType: String, Codable {
        case created = "created"
        case deleted = "deleted"
        case expired = "expired"
    }
}
