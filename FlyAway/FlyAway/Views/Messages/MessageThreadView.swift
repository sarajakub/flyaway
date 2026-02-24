import SwiftUI

struct MessageThreadView: View {
    let thread: MessageThread
    @ObservedObject var messageManager: MessageManager
    @State private var newMessageText = ""
    @State private var showingDeleteAlert = false
    @State private var messages: [Message] = []
    @FocusState private var isMessageFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(groupedMessages, id: \.date) { group in
                        DateHeaderView(date: group.date)
                        
                        ForEach(group.messages) { message in
                            MessageBubble(message: message)
                        }
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
                    .focused($isMessageFieldFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if !newMessageText.isEmpty {
                            sendMessage()
                        }
                    }
                
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
        .task {
            await refreshMessages()
        }
        .confirmationDialog("Delete Conversation", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    await messageManager.deleteThread(recipientName: thread.recipientName)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Delete all messages with \(thread.recipientName)?")
        }
    }
    
    private func sendMessage() {
        guard !newMessageText.isEmpty else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        Task {
            await messageManager.sendMessage(to: thread.recipientName, content: newMessageText)
            newMessageText = ""
            await refreshMessages()
        }
    }
    
    private func refreshMessages() async {
        await messageManager.fetchMessages()
        messages = messageManager.messageThreads.first(where: { $0.recipientName == thread.recipientName })?.messages ?? []
    }
    
    // Group messages by day like iMessage
    var groupedMessages: [(date: Date, messages: [Message])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.createdAt)
        }
        
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, messages: $0.value.sorted { $0.createdAt < $1.createdAt }) }
    }
}

struct DateHeaderView: View {
    let date: Date
    
    var body: some View {
        Text(date, style: .date)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
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
