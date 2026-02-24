import SwiftUI

struct HelpSupportView: View {
    @State private var showingFeedbackSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                    
                    Text("Help & Support")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("We're here for you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Crisis Resources - Most Important, Top of Page
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Crisis Resources")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    
                    Text("If you're in crisis or need immediate support")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        CrisisResourceCard(
                            title: "988 Suicide & Crisis Lifeline",
                            description: "24/7 phone support",
                            contactInfo: "988",
                            actionType: .call,
                            color: .red
                        )
                        
                        CrisisResourceCard(
                            title: "Crisis Text Line",
                            description: "24/7 text support",
                            contactInfo: "Text HOME to 741741",
                            actionType: .text,
                            color: .orange
                        )
                        
                        CrisisResourceCard(
                            title: "SAMHSA Helpline",
                            description: "Treatment referral service",
                            contactInfo: "1-800-662-4357",
                            actionType: .call,
                            color: .blue
                        )
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // App Guide
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.purple)
                        Text("How to Use FlyAway")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 10) {
                        GuideCard(icon: "text.bubble.fill", title: "Share Thoughts", description: "Express feelings privately or with the community")
                        GuideCard(icon: "bookmark.fill", title: "Save Thoughts", description: "Bookmark posts that resonate with you")
                        GuideCard(icon: "calendar.badge.clock", title: "Track Milestones", description: "Monitor important healing events")
                        GuideCard(icon: "paperplane.fill", title: "Release to Ether", description: "Let go of thoughts temporarily")
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Privacy
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("Privacy & Safety")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 10) {
                        GuideCard(icon: "person.fill.questionmark", title: "Anonymous by Default", description: "Posts are anonymous unless you choose otherwise")
                        GuideCard(icon: "clock.fill", title: "Temporary Posts", description: "Set expiration dates or send to ether")
                        GuideCard(icon: "hand.raised.fill", title: "Judgment-Free Zone", description: "Safe space for healing and growth")
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Feedback
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "megaphone.fill")
                            .foregroundColor(.purple)
                        Text("Share Feedback")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    
                    Button {
                        showingFeedbackSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .font(.title3)
                                .foregroundColor(.purple)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Report Bugs or Request Features")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Help us improve FlyAway")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFeedbackSheet) {
            FeedbackSheet()
        }
    }
}

struct CrisisResourceCard: View {
    let title: String
    let description: String
    let contactInfo: String
    let actionType: ContactActionType
    let color: Color
    
    enum ContactActionType {
        case call
        case text
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: actionType == .call ? "phone.fill" : "message.fill")
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if actionType == .call {
                Button(action: {
                    let phoneNumber = contactInfo.replacingOccurrences(of: "-", with: "")
                    if let url = URL(string: "tel://\(phoneNumber)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "phone.circle.fill")
                        Text("Call \(contactInfo)")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(color)
                    .cornerRadius(20)
                }
            } else {
                Button(action: {
                    if let url = URL(string: "sms:741741&body=HOME") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "message.circle.fill")
                        Text(contactInfo)
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(color)
                    .cornerRadius(20)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct GuideCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        HelpSupportView()
    }
}
