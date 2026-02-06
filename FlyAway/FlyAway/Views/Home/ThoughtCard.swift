import SwiftUI

struct ThoughtCard: View {
    let thought: Thought
    @EnvironmentObject var thoughtManager: ThoughtManager
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    Text(thought.category.emoji)
                    Text(thought.category.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                if let expiresAt = thought.expiresAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(timeRemaining(until: expiresAt))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                    Label("\(thought.saveCount)", systemImage: "bookmark.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .confirmationDialog("Delete this thought?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await thoughtManager.deleteThought(thought)
                }
            }
            Button("Cancel", role: .cancel) {}
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
        category: .healing
    ))
    .environmentObject(ThoughtManager())
    .padding()
}
