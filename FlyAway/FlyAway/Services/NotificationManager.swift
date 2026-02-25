import Foundation
import Combine
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        refreshAuthorizationStatus()
    }

    // MARK: - Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
            DispatchQueue.main.async { self.refreshAuthorizationStatus() }
            if let error { print("❌ Notification permission error: \(error.localizedDescription)") }
        }
    }

    private func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { self.authorizationStatus = settings.authorizationStatus }
        }
    }

    // MARK: - Scheduling

    /// Schedules an expiry notification for a thought.
    /// - Fires 1 day before expiry when window ≥ 2 days, otherwise at the midpoint.
    /// - Skipped for near-instant expiry (< 10 min — send-to-ether thoughts).
    func scheduleExpiryNotification(thoughtId: String, content: String, expiresAt: Date) {
        let timeUntilExpiry = expiresAt.timeIntervalSinceNow
        guard timeUntilExpiry > 600 else { return }

        let notifyAt: Date
        if timeUntilExpiry > 2 * 86_400 {
            notifyAt = expiresAt.addingTimeInterval(-86_400)   // 1 day before
        } else {
            notifyAt = Date().addingTimeInterval(timeUntilExpiry * 0.5) // Midpoint
        }

        let notifContent = UNMutableNotificationContent()
        notifContent.title = "Your thought is expiring soon"
        notifContent.body = String(content.prefix(120))
        notifContent.sound = .default
        notifContent.userInfo = ["thoughtId": thoughtId]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: notifyAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationId(for: thoughtId), content: notifContent, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("❌ Failed to schedule notification: \(error.localizedDescription)") }
            else { print("✅ Expiry notification scheduled for thought \(thoughtId)") }
        }
    }

    // MARK: - Cancellation

    func cancelExpiryNotification(thoughtId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationId(for: thoughtId)])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func notificationId(for thoughtId: String) -> String { "thought-expiry-\(thoughtId)" }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Show notification banner even when the app is foregrounded.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
