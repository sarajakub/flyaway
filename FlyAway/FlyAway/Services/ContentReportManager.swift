import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ContentReportManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var isSubmitting = false
    @Published var submitError: String?
    @Published var didSubmit = false

    /// Submit a report for a community thought.
    func submitReport(
        thoughtId: String,
        reportedUserId: String,
        reason: ContentReport.ReportReason,
        additionalContext: String? = nil
    ) async {
        guard let currentUser = Auth.auth().currentUser else {
            submitError = "You must be signed in to report content."
            return
        }
        isSubmitting = true
        submitError = nil

        let report = ContentReport(
            reportedThoughtId: thoughtId,
            reportedUserId: reportedUserId,
            reportingUserId: currentUser.uid,
            reason: reason,
            additionalContext: additionalContext?.isEmpty == true ? nil : additionalContext,
            createdAt: Date(),
            status: .pending
        )

        do {
            try db.collection("contentReports").addDocument(from: report)
            didSubmit = true
            AnalyticsManager.logContentReported(reason: reason.rawValue)
        } catch {
            submitError = "Could not submit report. Please try again."
        }
        isSubmitting = false
    }

    func reset() {
        didSubmit = false
        submitError = nil
    }
}
