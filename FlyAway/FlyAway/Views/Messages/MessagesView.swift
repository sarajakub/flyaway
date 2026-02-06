import SwiftUI

struct MessagesView: View {
    @StateObject private var messageManager = MessageManager()
    @State private var showingNewMessage = false
    
    var body: some View {
        ZStack {
            if messageManager.isLoading {
                ProgressView()
            } else if messageManager.messageThreads.isEmpty {
                EmptyMessagesView(showingNewMessage: $showingNewMessage)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messageManager.messageThreads) { thread in
                            NavigationLink(
                                destination: MessageThreadView(thread: thread, messageManager: messageManager)
                            ) {
                                MessageThreadCard(thread: thread)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewMessage = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.purple)
                }
            }
        }
        .sheet(isPresented: $showingNewMessage, onDismiss: {
            Task {
                await messageManager.fetchMessages()
            }
        }) {
            NewMessageSheet(messageManager: messageManager)
        }
        .task {
            await messageManager.fetchMessages()
        }
        .refreshable {
            await messageManager.fetchMessages()
        }
    }
}

struct EmptyMessagesView: View {
    @Binding var showingNewMessage: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "message.circle")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Messages Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Send a message to someone you miss.\nIt can help with the healing process.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingNewMessage = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("New Message")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: 200)
                .background(Color.purple)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct MessageThreadCard: View {
    let thread: MessageThread
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(thread.recipientName.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(thread.recipientName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(thread.messages.last?.content ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(thread.lastMessageDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    MessagesView()
}
