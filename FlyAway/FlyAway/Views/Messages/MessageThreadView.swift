import SwiftUI
import AVFoundation

struct MessageThreadView: View {
    let thread: MessageThread
    @ObservedObject var messageManager: MessageManager
    @State private var newMessageText = ""
    @State private var showingDeleteAlert = false
    @State private var messages: [Message] = []
    @State private var showingVoiceRecorder = false
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

            if showingVoiceRecorder {
                VoiceRecorderView { localURL in
                    showingVoiceRecorder = false
                    Task {
                        await messageManager.sendVoiceMessage(to: thread.recipientName, localURL: localURL)
                        await refreshMessages()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            } else {
                HStack(spacing: 12) {
                    Button(action: { showingVoiceRecorder = true }) {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.purple.opacity(0.1)))
                    }

                    TextField("Type a message...", text: $newMessageText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .lineLimit(1...5)
                        .focused($isMessageFieldFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            if !newMessageText.isEmpty { sendMessage() }
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

    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                if message.isVoice {
                    VoiceBubble(audioURL: message.audioURL, player: $player, isPlaying: $isPlaying)
                } else {
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
                }

                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }

            Spacer()
        }
    }
}

struct VoiceBubble: View {
    let audioURL: String?
    @Binding var player: AVAudioPlayer?
    @Binding var isPlaying: Bool

    var body: some View {
        Button(action: togglePlayback) {
            HStack(spacing: 10) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)

                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.85))

                Text("Voice message")
                    .font(.callout)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
        }
    }

    private func togglePlayback() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            guard let urlString = audioURL, let url = URL(string: urlString) else { return }
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else {
                    let msg = error?.localizedDescription ?? "unknown"
                    print("❌ Voice message download error: \(msg)")
                    return
                }
                DispatchQueue.main.async {
                    do {
                        let audioPlayer = try AVAudioPlayer(data: data)
                        player = audioPlayer
                        audioPlayer.play()
                        isPlaying = true
                        Timer.scheduledTimer(withTimeInterval: audioPlayer.duration, repeats: false) { _ in
                            isPlaying = false
                        }
                    } catch {
                        print("❌ Voice message playback error: \(error.localizedDescription)")
                    }
                }
            }.resume()
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
