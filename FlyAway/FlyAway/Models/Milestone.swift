import Foundation
import FirebaseFirestore

struct Milestone: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    var title: String
    var eventDate: Date
    let createdAt: Date
    
    var daysSince: Int {
        Calendar.current.dateComponents([.day], from: eventDate, to: Date()).day ?? 0
    }
    
    var timeSinceText: String {
        let days = daysSince
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
}
