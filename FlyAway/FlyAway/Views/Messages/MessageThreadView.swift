import SwiftUI
import AVFoundation
import FirebaseStorage

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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                if message.isVoice {
                    VoiceBubble(audioPath: message.audioURL)
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

// MARK: - iMessage-style Voice Bubble

struct VoiceBubble: View {
    /// Firebase Storage path (e.g. "voiceMessages/uid/abc.m4a")
    /// or a legacy https:// download URL for messages recorded before this fix.
    let audioPath: String?

    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var isLoading = false
    @State private var progress: Double = 0          // 0...1
    @State private var duration: TimeInterval = 0
    @State private var progressTimer: Timer?

    var body: some View {
        HStack(spacing: 10) {
            // Play / pause / loading button
            Button(action: togglePlayback) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 36, height: 36)
                    if isLoading {
                        ProgressView().tint(.white).scaleEffect(0.75)
                    } else {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.callout.weight(.bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(isLoading)

            VStack(alignment: .leading, spacing: 3) {
                // Waveform
                WaveformBarsView(
                    progress: progress,
                    seed: audioPath ?? "default"
                )
                .frame(height: 28)

                // Duration / countdown
                Text(timeString(isPlaying && duration > 0 ? duration * (1 - progress) : duration))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .onDisappear { stopPlayback() }
    }

    // MARK: - Playback

    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else if let existingPlayer = player, existingPlayer.currentTime > 0 {
            // Resume from paused position
            existingPlayer.play()
            isPlaying = true
            startProgressTimer()
        } else {
            loadAndPlay()
        }
    }

    private func loadAndPlay() {
        guard let path = audioPath else { return }
        isLoading = true

        let resolveAndPlay: (URL) -> Void = { url in
            URLSession.shared.dataTask(with: url) { data, _, error in
                DispatchQueue.main.async {
                    guard let data, error == nil else {
                        isLoading = false
                        let desc = error?.localizedDescription ?? "unknown"
                        print("❌ Voice download error: \(desc)")
                        return
                    }
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                        try AVAudioSession.sharedInstance().setActive(true)
                        let p = try AVAudioPlayer(data: data)
                        player = p
                        duration = p.duration
                        p.play()
                        isPlaying = true
                        isLoading = false
                        startProgressTimer()
                    } catch {
                        isLoading = false
                        print("❌ Voice playback error: \(error.localizedDescription)")
                    }
                }
            }.resume()
        }

        if path.hasPrefix("https://") {
            // Legacy messages stored with a direct download URL
            if let url = URL(string: path) { resolveAndPlay(url) }
            else { isLoading = false }
        } else {
            // Current approach: resolve via authenticated Storage SDK
            Storage.storage().reference(withPath: path).downloadURL { url, error in
                if let url {
                    resolveAndPlay(url)
                } else {
                    DispatchQueue.main.async {
                        isLoading = false
                        let desc = error?.localizedDescription ?? "unknown"
                        print("❌ Storage URL error: \(desc)")
                    }
                }
            }
        }
    }

    private func stopPlayback() {
        player?.pause()
        isPlaying = false
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard let p = player else { return }
            if p.isPlaying {
                progress = p.duration > 0 ? p.currentTime / p.duration : 0
            } else {
                // Finished naturally
                isPlaying = false
                progress = 0
                progressTimer?.invalidate()
                progressTimer = nil
            }
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let secs = max(0, Int(t))
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }
}

// MARK: - Waveform Bars

struct WaveformBarsView: View {
    let progress: Double  // 0...1 — bars up to this point are full-white
    let seed: String       // used for deterministic bar heights per message

    private static let barCount = 30

    /// Generates a deterministic, natural-looking waveform from any seed string.
    private func barHeights() -> [CGFloat] {
        var hash = seed.unicodeScalars.reduce(5381) { ($0 << 5) &+ $0 &+ Int($1.value) }
        return (0..<Self.barCount).map { i in
            hash = hash &* 1664525 &+ 1013904223
            let raw = CGFloat(abs(hash) % 100) / 100.0          // 0...1
            // Blend with a bell-curve envelope so edges are shorter than centre
            let pos = CGFloat(i) / CGFloat(Self.barCount - 1) - 0.5  // -0.5...0.5
            let envelope = 1.0 - pos * pos * 2.2
            return max(0.15, min(1.0, raw * 0.65 + envelope * 0.35))
        }
    }

    var body: some View {
        let heights = barHeights()
        HStack(spacing: 2) {
            ForEach(0..<Self.barCount, id: \.self) { i in
                let filled = Double(i) / Double(Self.barCount) <= progress
                Capsule()
                    .fill(filled ? Color.white : Color.white.opacity(0.35))
                    .frame(width: 2.5, height: heights[i] * 26)
                    .animation(.linear(duration: 0.04), value: progress)
            }
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
