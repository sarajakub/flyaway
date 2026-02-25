import SwiftUI
import AVFoundation

/// Inline voice recorder used in the message thread input bar.
/// Shows a mic button while idle. While recording, shows a live timer + stop button.
/// After recording, shows a compact preview row with play / trash / send.
struct VoiceRecorderView: View {
    /// Called with the local temporary audio file URL when the user taps Send.
    let onSend: (URL) -> Void

    @State private var recorder: AVAudioRecorder?
    @State private var player: AVAudioPlayer?
    @State private var recordingURL: URL?

    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        Group {
            if recordingURL != nil {
                previewRow
            } else {
                micButton
            }
        }
    }

    // MARK: - Mic Button

    private var micButton: some View {
        Button(action: toggleRecording) {
            HStack(spacing: 6) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                    .font(.title3)
                    .foregroundColor(isRecording ? .red : .purple)

                if isRecording {
                    Text(formatted(elapsed))
                        .font(.callout.monospacedDigit())
                        .foregroundColor(.red)

                    // Pulsing dot
                    Circle()
                        .fill(.red)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(.red.opacity(0.35), lineWidth: 5).scaleEffect(1.6))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
    }

    // MARK: - Preview Row

    private var previewRow: some View {
        HStack(spacing: 10) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
            }

            Text(formatted(elapsed))
                .font(.callout.monospacedDigit())
                .foregroundColor(.secondary)

            Spacer()

            Button(action: discard) {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red.opacity(0.8))
            }

            Button(action: sendVoice) {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.purple))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).cornerRadius(20))
    }

    // MARK: - Recording

    private func toggleRecording() { isRecording ? stopRecording() : startRecording() }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("voice_\(Int(Date().timeIntervalSince1970)).m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()

            isRecording = true
            elapsed = 0
            // Schedule on RunLoop.main so @State updates trigger redraws correctly
            timer = Timer(timeInterval: 1, repeats: true) { [self] _ in
                elapsed += 1
                if elapsed >= 120 { stopRecording() } // 2-minute limit
            }
            RunLoop.main.add(timer!, forMode: .common)
        } catch {
            print("❌ VoiceRecorder start error: \(error.localizedDescription)")
        }
    }

    private func stopRecording() {
        timer?.invalidate(); timer = nil
        guard let rec = recorder else { return }
        let url = rec.url
        rec.stop()
        recorder = nil
        isRecording = false
        recordingURL = url
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Playback

    private func togglePlayback() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            guard let url = recordingURL else { return }
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.play()
                isPlaying = true
                Timer.scheduledTimer(withTimeInterval: player?.duration ?? 0, repeats: false) { _ in
                    isPlaying = false
                }
            } catch {
                print("❌ VoiceRecorder playback error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Actions

    private func discard() {
        player?.stop()
        if let url = recordingURL { try? FileManager.default.removeItem(at: url) }
        recordingURL = nil
        isPlaying = false
        elapsed = 0
    }

    private func sendVoice() {
        guard let url = recordingURL else { return }
        player?.stop()
        isPlaying = false
        // Nil out state before handing off so the recorder can't reuse the URL
        recordingURL = nil
        elapsed = 0
        onSend(url)
    }

    // MARK: - Helpers

    private func formatted(_ seconds: TimeInterval) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}
