import SwiftUI

struct ThoughtCard: View {
    let thought: Thought
    @EnvironmentObject var thoughtManager: ThoughtManager
    @EnvironmentObject var a11ySettings: AccessibilitySettings
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    Text(thought.category.emoji)
                        .accessibilityHidden(true)
                    Text(thought.category.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(thought.category.rawValue)
                
                Spacer()
                
                if let expiresAt = thought.expiresAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .accessibilityHidden(true)
                        Text(timeRemaining(until: expiresAt))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Expires \(timeRemaining(until: expiresAt))")
                }
            }
            
            Text(thought.content)
                .font(.body)
                .lineLimit(nil)
            
            HStack {
                Text(thought.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Label("\(thought.saveCount) saves", systemImage: "bookmark.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .accessibilityLabel("\(thought.saveCount) saves")
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                            // Minimum 44×44pt touch target (WCAG 2.5.5)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Delete thought")
                    .accessibilityHint("Permanently removes this thought")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .confirmationDialog("Delete this thought?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if !a11ySettings.hapticsReduced {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                }
                Task {
                    await thoughtManager.deleteThought(thought)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func timeRemaining(until date: Date) -> String {
        let remaining = date.timeIntervalSince(Date())
        
        if remaining < 60 {
            return "Expires soon"
        } else if remaining < 3600 {
            let minutes = Int(remaining / 60)
            return "\(minutes)m left"
        } else if remaining < 86400 {
            let hours = Int(remaining / 3600)
            return "\(hours)h left"
        } else {
            let days = Int(remaining / 86400)
            return "\(days)d left"
        }
    }
}

#Preview {
    ThoughtCard(thought: Thought(
        userId: "123",
        userName: "Sara",
        content: "Today I'm choosing to let go of what I cannot control. Each breath brings me closer to peace.",
        isPublic: true,
        createdAt: Date(),
        expiresAt: Date().addingTimeInterval(86400),
        isVoice: false,
        audioURL: nil,
        tags: [],
        saveCount: 5,
        category: .healing,
        reactionCounts: [:]
    ))
    .environmentObject(ThoughtManager())
    .environmentObject(AccessibilitySettings())
    .padding()
}
