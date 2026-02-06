import SwiftUI

struct MessageThreadView: View {
    let thread: MessageThread
    @ObservedObject var messageManager: MessageManager
    @State private var newMessageText = ""
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(thread.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack(spacing: 12) {
                TextField("Type a message...", text: $newMessageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(newMessageText.isEmpty ? Color.gray : Color.purple)
                        )
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(thread.recipientName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Conversation", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await messageManager.deleteThread(recipientName: thread.recipientName)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete all messages with \(thread.recipientName)?")
        }
    }
    
    private func sendMessage() {
        guard !newMessageText.isEmpty else { return }
        
        Task {
            await messageManager.sendMessage(to: thread.recipientName, content: newMessageText)
            newMessageText = ""
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        MessageThreadView(
            thread: MessageThread(
                recipientName: "Mom",
                messages: [
                    Message(userId: "123", recipientName: "Mom", content: "I miss you so much today", createdAt: Date(), isRead: false)
                ]
            ),
            messageManager: MessageManager()
        )
    }
}
