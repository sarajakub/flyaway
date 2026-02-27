import Foundation
import FirebaseFirestore

/// Represents a user-submitted report on a community thought.
struct ContentReport: Identifiable, Codable {
    @DocumentID var id: String?
    let reportedThoughtId: String
    let reportedUserId: String   // userId on the thought being reported
    let reportingUserId: String  // who filed the report
    let reason: ReportReason
    let additionalContext: String?
    let createdAt: Date
    var status: ReportStatus

    enum ReportReason: String, Codable, CaseIterable {
        case harmful       = "Harmful or dangerous content"
        case harassment    = "Harassment or bullying"
        case selfHarm      = "Self-harm or suicide glorification"
        case misinformation = "Misinformation"
        case spam          = "Spam or irrelevant"
        case other         = "Other"
    }

    enum ReportStatus: String, Codable {
        case pending  = "pending"
        case reviewed = "reviewed"
        case resolved = "resolved"
    }
}
