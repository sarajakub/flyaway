import Foundation
import FirebaseAnalytics

/// Centralised, strongly-typed wrapper around Firebase Analytics.
/// Call these functions at the relevant points in the UI to populate
/// the Firebase console dashboard without scattering raw strings everywhere.
enum AnalyticsManager {

    // MARK: - Authentication

    static func logSignUp(method: String = "email") {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    static func logSignIn(method: String = "email") {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    // MARK: - Thoughts

    static func logThoughtCreated(category: String, isPublic: Bool) {
        Analytics.logEvent("thought_created", parameters: [
            "category": category,
            "is_public": isPublic ? "true" : "false"
        ])
    }

    static func logThoughtSentToEther(category: String) {
        Analytics.logEvent("thought_sent_to_ether", parameters: [
            "category": category
        ])
    }

    static func logThoughtSaved() {
        Analytics.logEvent("thought_saved", parameters: nil)
    }

    static func logThoughtDeleted() {
        Analytics.logEvent("thought_deleted", parameters: nil)
    }

    // MARK: - Community

    static func logCommunityReaction(reactionType: String) {
        Analytics.logEvent("community_reaction_added", parameters: [
            "reaction_type": reactionType
        ])
    }

    static func logContentReported(reason: String) {
        Analytics.logEvent("content_reported", parameters: [
            "reason": reason
        ])
    }

    // MARK: - Messages

    static func logMessageSent() {
        Analytics.logEvent("message_sent", parameters: nil)
    }

    // MARK: - Mood

    static func logMoodCheckedIn(mood: String) {
        Analytics.logEvent("mood_checked_in", parameters: [
            "mood": mood
        ])
    }

    // MARK: - Milestones

    static func logMilestoneReached(title: String) {
        Analytics.logEvent("milestone_reached", parameters: [
            "milestone_title": title
        ])
    }

    // MARK: - Onboarding

    static func logOnboardingCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: nil)
    }

    // MARK: - Mindfulness

    static func logMindfulnessStarted(resourceTitle: String) {
        Analytics.logEvent("mindfulness_started", parameters: [
            "resource_title": resourceTitle
        ])
    }

    // MARK: - Account

    static func logAccountDeleted() {
        Analytics.logEvent("account_deleted", parameters: nil)
    }

    // MARK: - Screen views (call from .onAppear)

    static func logScreenView(name: String, className: String = "") {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name,
            AnalyticsParameterScreenClass: className.isEmpty ? name : className
        ])
    }
}
