import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var bio: String?
    var createdAt: Date
    var followers: [String]
    var following: [String]
    var isAnonymous: Bool
    var profileImageURL: String?
    
    var followerCount: Int {
        followers.count
    }
    
    var followingCount: Int {
        following.count
    }
}

struct UserFollow: Identifiable, Codable {
    @DocumentID var id: String?
    var followerId: String
    var followingId: String
    var createdAt: Date
}
