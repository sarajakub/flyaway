import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle).fontWeight(.bold)
                Text("Last updated: June 2025")
                    .font(.subheadline).foregroundColor(.secondary)

                Group {
                    PolicySection(title: "1. Who We Are") {
                        "FlyAway is a mental health and healing application built to help people process emotions, release thoughts, and find community. This policy explains how we collect, use, and protect your information."
                    }

                    PolicySection(title: "2. Information We Collect") {
                        """
• **Account information**: email address and display name you provide at sign-up.
• **Content you create**: thoughts, mood entries, messages, and audio recordings you submit.
• **Usage data**: app interactions, feature usage patterns, and crash reports (via Firebase Analytics and Crashlytics).
• **Device information**: iOS version, device model, and timezone — used only for debugging and analytics.

We do not collect or sell personally identifiable information to third parties for advertising purposes.
"""
                    }

                    PolicySection(title: "3. How We Use Your Information") {
                        """
• To provide, operate, and improve the FlyAway app.
• To personalise your experience (e.g. mood history, saved thoughts).
• To maintain community safety through content moderation.
• To send important service notifications (not marketing without consent).
• To analyse aggregated, anonymised usage trends.
"""
                    }

                    PolicySection(title: "4. Data Storage") {
                        "All data is stored securely using Google Firebase (Firestore, Firebase Auth, Cloud Storage). Firebase servers are operated by Google LLC and may be located outside your country. Data is encrypted in transit (TLS) and at rest."
                    }

                    PolicySection(title: "5. Data Retention") {
                        """
• Thoughts are retained until you delete them or they expire (configurable per thought).
• Messages are retained until deleted by either participant.
• Your account data is retained until you request deletion.
• Anonymous analytics data may be retained indefinitely in aggregated form.
"""
                    }

                    PolicySection(title: "6. Account Deletion") {
                        "You may delete your account at any time from Settings → Delete Account. Doing so permanently and irreversibly removes all your thoughts, messages, mood entries, milestones, and authentication credentials. This process completes immediately and cannot be undone."
                    }

                    PolicySection(title: "7. Sharing Your Information") {
                        """
We do not sell, rent, or share your personal information with third parties, except:
• **Service providers** (Firebase / Google) necessary to operate the app.
• **Legal requirements**: if required by law, court order, or to protect safety.
• **Business transfers**: in the event of a merger or acquisition, under equivalent privacy protections.
"""
                    }

                    PolicySection(title: "8. Children's Privacy") {
                        "FlyAway is intended for users aged 17 and older. We do not knowingly collect information from children under 13. If you believe a child has provided us personal information, please contact us immediately."
                    }

                    PolicySection(title: "9. Your Rights") {
                        """
Depending on your location, you may have rights to:
• Access the personal data we hold about you.
• Correct inaccurate data.
• Request deletion of your data (see Section 6).
• Withdraw consent for analytics.

To exercise these rights, contact us at the email below.
"""
                    }

                    PolicySection(title: "10. Contact Us") {
                        "If you have questions about this Privacy Policy, please contact us at: privacy@flyaway.app"
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - PolicySection helper

private struct PolicySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    // Convenience init for plain strings
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }
}

extension PolicySection where Content == Text {
    init(title: String, body: () -> String) {
        self.title = title
        self.content = { Text(body()) }
    }
}

#Preview {
    NavigationView { PrivacyPolicyView() }
}
