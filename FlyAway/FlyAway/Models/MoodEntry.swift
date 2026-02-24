import Foundation
import FirebaseFirestore

struct MoodEntry: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let mood: Int // 1-5 scale
    let note: String?
    let createdAt: Date
    
    var moodEmoji: String {
        switch mood {
        case 1: return "😢"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }
    
    var moodLabel: String {
        switch mood {
        case 1: return "Very Bad"
        case 2: return "Bad"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Okay"
        }
    }
}
