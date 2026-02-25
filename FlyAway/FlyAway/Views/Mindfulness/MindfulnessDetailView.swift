import SwiftUI
import AVFoundation
import Combine

// MARK: - Detail view (router)

struct MindfulnessDetailView: View {
    let resource: MindfulnessResource
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.85), Color.blue.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 220)

                    VStack(spacing: 12) {
                        Image(systemName: resource.type.icon)
                            .font(.system(size: 52))
                            .foregroundColor(.white)

                        Text(resource.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(resource.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }
                .cornerRadius(20)
                .padding()

                // Interactive content
                Group {
                    switch resource.payload {
                    case .breathwork(let inhale, let hold1, let exhale, let hold2, let cycles):
                        BreathworkView(inhale: inhale, hold1: hold1, exhale: exhale, hold2: hold2, totalCycles: cycles)

                    case .journaling(let prompts):
                        JournalingView(prompts: prompts, onComplete: { dismiss() })

                    case .affirmations(let cards):
                        AffirmationsView(cards: cards)

                    case .meditation(let steps):
                        MeditationView(steps: steps, onComplete: { dismiss() })
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Breathwork

private struct BreathworkView: View {
    let inhale: Int
    let hold1: Int
    let exhale: Int
    let hold2: Int
    let totalCycles: Int

    enum Phase: String { case inhale = "Inhale", hold1 = "Hold", exhale = "Exhale", hold2 = "Pause", done = "Done" }

    @State private var isRunning = false
    @State private var phase: Phase = .inhale
    @State private var secondsLeft: Int = 0
    @State private var cyclesDone: Int = 0
    @State private var scale: CGFloat = 0.55
    @State private var timer: Timer? = nil

    var body: some View {
        VStack(spacing: 32) {
            // Animated circle
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.15)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .frame(width: 260, height: 260)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: Double(currentPhaseDuration())), value: scale)

                VStack(spacing: 6) {
                    Text(isRunning ? phase.rawValue : "Ready")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)

                    if isRunning && phase != .done {
                        Text("\(secondsLeft)")
                            .font(.system(size: 44, weight: .thin, design: .rounded))
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding(.top, 8)

            // Cycle counter
            if isRunning || cyclesDone > 0 {
                HStack(spacing: 8) {
                    ForEach(0..<totalCycles, id: \.self) { i in
                        Circle()
                            .fill(i < cyclesDone ? Color.purple : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
            }

            // Pattern label
            HStack(spacing: 20) {
                PatternPill(label: "In", value: inhale)
                if hold1 > 0 { PatternPill(label: "Hold", value: hold1) }
                PatternPill(label: "Out", value: exhale)
                if hold2 > 0 { PatternPill(label: "Pause", value: hold2) }
            }

            Button(action: toggle) {
                Text(isRunning ? "Pause" : (cyclesDone > 0 && cyclesDone < totalCycles ? "Resume" : (phase == .done ? "Start Over" : "Begin")))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isRunning ? Color.gray : Color.purple)
                    .cornerRadius(14)
            }
        }
        .padding(.vertical, 24)
        .onDisappear { stopTimer() }
    }

    private func toggle() {
        if phase == .done { reset(); return }
        isRunning ? stopTimer() : startTimer()
        isRunning.toggle()
    }

    private func reset() {
        stopTimer()
        phase = .inhale
        cyclesDone = 0
        secondsLeft = inhale
        scale = 0.55
        isRunning = false
    }

    private func startTimer() {
        if secondsLeft == 0 { secondsLeft = currentPhaseDuration() }
        updateScale()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            secondsLeft -= 1
            if secondsLeft <= 0 { advancePhase() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func advancePhase() {
        switch phase {
        case .inhale:
            if hold1 > 0 { phase = .hold1; secondsLeft = hold1 }
            else { phase = .exhale; secondsLeft = exhale }
        case .hold1:
            phase = .exhale; secondsLeft = exhale
        case .exhale:
            if hold2 > 0 { phase = .hold2; secondsLeft = hold2 }
            else { completeCycle() }
        case .hold2:
            completeCycle()
        case .done:
            break
        }
        updateScale()
    }

    private func completeCycle() {
        cyclesDone += 1
        if cyclesDone >= totalCycles {
            phase = .done
            stopTimer()
            isRunning = false
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.success)
        } else {
            phase = .inhale
            secondsLeft = inhale
        }
    }

    private func updateScale() {
        switch phase {
        case .inhale: scale = 1.0
        case .hold1:  scale = 1.0
        case .exhale: scale = 0.55
        case .hold2:  scale = 0.55
        case .done:   scale = 0.75
        }
    }

    private func currentPhaseDuration() -> Int {
        switch phase {
        case .inhale: return inhale
        case .hold1:  return hold1
        case .exhale: return exhale
        case .hold2:  return hold2
        case .done:   return 0
        }
    }
}

private struct PatternPill: View {
    let label: String
    let value: Int
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)s")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.purple.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Journaling

private struct JournalingView: View {
    let prompts: [String]
    let onComplete: (() -> Void)?
    @State private var index = 0
    @StateObject private var speech = SpeechManager()

    var body: some View {
        VStack(spacing: 24) {
            // Progress
            HStack(spacing: 6) {
                ForEach(0..<prompts.count, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? Color.purple : Color.gray.opacity(0.25))
                        .frame(height: 4)
                }
            }

            // Prompt card
            VStack(spacing: 16) {
                HStack {
                    Text("Prompt \(index + 1) of \(prompts.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        if speech.isSpeaking { speech.stop() } else { speech.speak(prompts[index]) }
                    } label: {
                        Image(systemName: speech.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .padding(8)
                            .background(Color.purple.opacity(0.08))
                            .clipShape(Circle())
                    }
                }

                Text(prompts[index])
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .background(Color.purple.opacity(0.07))
                    .cornerRadius(18)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(index)
            }
            .animation(.easeInOut(duration: 0.35), value: index)

            Text("Take a moment to reflect, then write in your own journal.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Navigation
            HStack(spacing: 16) {
                Button {
                    if index > 0 { index -= 1 }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.subheadline)
                    .foregroundColor(index == 0 ? .gray : .purple)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(index == 0)

                Button {
                    speech.stop()
                    if index < prompts.count - 1 {
                        index += 1
                    } else {
                        onComplete?()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(index == prompts.count - 1 ? "Done" : "Next")
                        Image(systemName: index == prompts.count - 1 ? "checkmark" : "chevron.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.purple)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 24)
        .onDisappear { speech.stop() }
    }
}

// MARK: - Affirmations

private struct AffirmationsView: View {
    let cards: [String]
    @State private var index = 0
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 28) {
            Text("\(index + 1) / \(cards.count)")
                .font(.caption)
                .foregroundColor(.secondary)

            // Card stack effect (show 2 cards behind)
            ZStack {
                ForEach((max(0, index - 1)..<min(cards.count, index + 2)).reversed(), id: \.self) { i in
                    if i != index {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(LinearGradient(
                                colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .scaleEffect(0.92)
                    }
                }

                // Front card
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(LinearGradient(
                            colors: [Color.purple.opacity(0.75), Color.blue.opacity(0.65)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))

                    Text(cards[index])
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(28)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .offset(x: dragOffset)
                .rotationEffect(.degrees(Double(dragOffset) / 30))
                .gesture(
                    DragGesture()
                        .onChanged { dragOffset = $0.translation.width }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                if value.translation.width < -60 && index < cards.count - 1 {
                                    index += 1
                                } else if value.translation.width > 60 && index > 0 {
                                    index -= 1
                                }
                                dragOffset = 0
                            }
                            let g = UIImpactFeedbackGenerator(style: .light)
                            g.impactOccurred()
                        }
                )
                .animation(.spring(response: 0.4), value: index)
                .id(index)
            }

            Text("Swipe left or right to move between cards")
                .font(.caption)
                .foregroundColor(.secondary)

            // Dot indicator
            HStack(spacing: 8) {
                ForEach(0..<cards.count, id: \.self) { i in
                    Circle()
                        .fill(i == index ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: i == index ? 10 : 7, height: i == index ? 10 : 7)
                        .animation(.spring(), value: index)
                }
            }

            // Button nav as fallback
            HStack(spacing: 16) {
                Button {
                    withAnimation { if index > 0 { index -= 1 } }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(index == 0 ? .gray : .purple)
                        .frame(width: 52, height: 52)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(index == 0)

                Spacer()

                Button {
                    withAnimation { if index < cards.count - 1 { index += 1 } }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(index == cards.count - 1 ? .gray : .purple)
                        .frame(width: 52, height: 52)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(index == cards.count - 1)
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 24)
    }
}

// MARK: - Meditation

private struct MeditationView: View {
    let steps: [String]
    let onComplete: (() -> Void)?
    @State private var activeStep = 0
    @State private var autoAdvance = false
    @StateObject private var speech = SpeechManager()

    var body: some View {
        VStack(spacing: 16) {

            // Controls row
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(activeStep < steps.count ? "Tap the highlighted step when ready" : "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "speaker.wave.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Toggle("", isOn: $autoAdvance)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                    .scaleEffect(0.8, anchor: .trailing)
            }
            .padding(.horizontal, 4)

            // Steps
            VStack(spacing: 14) {
                ForEach(steps.indices, id: \.self) { i in
                    VStack(spacing: 0) {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(stepColor(i))
                                    .frame(width: 32, height: 32)
                                if i < activeStep {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(i + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(i == activeStep ? .white : .secondary)
                                }
                            }

                            Text(steps[i])
                                .font(.body)
                                .foregroundColor(stepTextColor(i))
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(i == activeStep ? Color.purple.opacity(0.08) : Color.clear)
                                .cornerRadius(12)
                                .animation(.easeInOut(duration: 0.3), value: activeStep)

                            // TTS speaker button (visible for active step and completed steps)
                            if i <= activeStep && activeStep < steps.count {
                                Button {
                                    if speech.isSpeaking && speech.speakingIndex == i {
                                        speech.stop()
                                    } else {
                                        speech.speak(steps[i], index: i)
                                    }
                                } label: {
                                    Image(systemName: speech.isSpeaking && speech.speakingIndex == i
                                          ? "speaker.wave.2.fill" : "speaker.wave.2")
                                        .font(.caption)
                                        .foregroundColor(speech.isSpeaking && speech.speakingIndex == i
                                                         ? .purple : .secondary)
                                        .padding(6)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard i == activeStep, activeStep < steps.count else { return }
                            speech.stop()
                            withAnimation(.spring()) { activeStep += 1 }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            if autoAdvance && activeStep < steps.count {
                                speech.speak(steps[activeStep], index: activeStep)
                            }
                        }

                        if i < steps.count - 1 {
                            HStack {
                                Color.gray.opacity(0.2)
                                    .frame(width: 2, height: 16)
                                    .padding(.leading, 20)
                                Spacer()
                            }
                        }
                    }
                }
            }

            // Completion
            if activeStep >= steps.count {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.purple)
                    Text("Well done. Take a moment.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 16) {
                        Button("Start Over") {
                            withAnimation { activeStep = 0 }
                            speech.stop()
                        }
                        .foregroundColor(.purple)

                        Button("Done") {
                            onComplete?()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .padding(.vertical, 24)
        .onDisappear { speech.stop() }
        // Auto-advance: when TTS finishes naturally, advance to next step
        .onChange(of: speech.naturalFinishCount) { _, _ in
            guard autoAdvance, activeStep < steps.count else { return }
            let next = activeStep + 1
            withAnimation(.spring()) { activeStep = next }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if next < steps.count {
                speech.speak(steps[next], index: next)
            }
        }
        // When auto-advance is turned on mid-session, start speaking the current step
        .onChange(of: autoAdvance) { _, on in
            if on, activeStep < steps.count {
                speech.speak(steps[activeStep], index: activeStep)
            } else {
                speech.stop()
            }
        }
    }

    private func stepColor(_ i: Int) -> Color {
        i <= activeStep ? .purple : Color.gray.opacity(0.2)
    }

    private func stepTextColor(_ i: Int) -> Color {
        if i < activeStep { return .secondary }
        if i == activeStep { return .primary }
        return .secondary.opacity(0.6)
    }
}

// MARK: - Speech Manager

fileprivate class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var speakingIndex: Int = -1
    /// Increments only on natural (non-interrupted) finish — safe to observe in onChange
    @Published var naturalFinishCount: Int = 0
    private var wasStopped = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, index: Int = 0) {
        wasStopped = false
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestVoice()
        utterance.rate = 0.45
        utterance.postUtteranceDelay = 0.3
        speakingIndex = index
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        wasStopped = true
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        speakingIndex = -1
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.speakingIndex = -1
            if !self.wasStopped {
                self.naturalFinishCount += 1
            }
            self.wasStopped = false
        }
    }

    private func bestVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        return voices.first(where: { $0.quality == .premium })
            ?? voices.first(where: { $0.quality == .enhanced })
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        MindfulnessDetailView(resource: MindfulnessResource.samples[0])
    }
}

