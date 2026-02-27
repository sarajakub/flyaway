import SwiftUI

// MARK: - Paper Airplane Vector Shape
/// Classic delta-wing dart, pointing right. Coordinates are proportional to bounds.
struct PaperAirplaneVectorShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        let nose    = CGPoint(x: w,        y: h * 0.50)
        let topBack = CGPoint(x: 0,        y: 0       )
        let botBack = CGPoint(x: 0,        y: h       )
        let topFold = CGPoint(x: w * 0.52, y: h * 0.24)
        let botFold = CGPoint(x: w * 0.52, y: h * 0.76)
        let topGrip = CGPoint(x: w * 0.18, y: h * 0.43)
        let botGrip = CGPoint(x: w * 0.18, y: h * 0.57)

        // Top wing
        p.move(to: nose); p.addLine(to: topBack); p.addLine(to: topGrip); p.addLine(to: topFold); p.closeSubpath()
        // Bottom wing
        p.move(to: nose); p.addLine(to: botFold); p.addLine(to: botGrip); p.addLine(to: botBack); p.closeSubpath()
        // Center body
        p.move(to: nose); p.addLine(to: topFold); p.addLine(to: topGrip); p.addLine(to: botGrip); p.addLine(to: botFold); p.closeSubpath()

        return p
    }
}

// MARK: - Note Lines Shape
private struct NoteLinesShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let xStart: CGFloat = w * 0.12
        let xEnd:   CGFloat = w * 0.88

        for i in 0..<5 {
            let y       = h * (0.22 + CGFloat(i) * 0.135)
            let lineEnd = i == 4 ? xEnd * 0.60 : xEnd
            p.move(to: CGPoint(x: xStart, y: y))
            p.addLine(to: CGPoint(x: lineEnd, y: y))
        }
        return p
    }
}

// MARK: - Throw Phase
private enum ThrowPhase {
    case folding, ready, dragging, flying
}

// MARK: - Paper Airplane Throw View
/// Full-screen overlay: paper folds into an airplane, user swipes it off screen.
/// `onComplete` fires when the plane exits OR the user taps Skip.
struct PaperAirplaneThrowView: View {
    let onComplete: () -> Void

    @State private var phase: ThrowPhase = .folding
    @State private var foldProgress: CGFloat = 0.0
    @State private var confirmOpacity: Double = 0.0

    // Plane position state — only ONE offset animated at a time to avoid NaN
    @State private var planeOffset: CGSize = .zero
    @State private var planeAngle: Double = 0.0
    @State private var planeOpacity: Double = 1.0

    @State private var floatUp: Bool = false
    @State private var hintOpacity: Double = 0.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Near-full dark background — form content should not compete ──
                Color.black.opacity(0.90)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                // ── Confirmation header ────────────────────────────────────
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(UIColor.systemGreen))
                            .font(.body)
                        Text("Thought sent")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.10), in: Capsule())
                    .padding(.top, geo.safeAreaInsets.top + 24)
                    .opacity(confirmOpacity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Thought sent successfully")

                    Spacer()
                }

                // ── Paper / Airplane ──────────────────────────────────────
                planeStack
                    .rotationEffect(.degrees(planeAngle))
                    .offset(
                        x: planeOffset.width,
                        // Slight upward bias from center; idle float applied here
                        y: planeOffset.height - geo.size.height * 0.08
                            + (phase == .ready ? (floatUp ? -7 : 7) : 0)
                    )
                    .opacity(planeOpacity)
                    .gesture(throwGesture(screenSize: geo.size))
                    .accessibilityLabel("Paper airplane")
                    .accessibilityHint("Swipe in any direction to release your thought")
                    .accessibilityAddTraits(.isButton)

                // ── Instruction label ──────────────────────────────────────
                VStack {
                    Spacer()

                    // Shown only when ready and not dragging
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.65))
                        Text("Swipe to release")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .opacity(phase == .ready ? hintOpacity : 0)
                    .animation(.easeInOut(duration: 0.2), value: phase)
                    .accessibilityHidden(true) // redundant with plane's accessibilityHint

                    Spacer()
                        .frame(height: geo.size.height * 0.26)
                }

                // ── Skip button ───────────────────────────────────────────
                VStack {
                    Spacer()
                    Button {
                        onComplete()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.75))
                            // Minimum 44×44pt touch target (WCAG 2.5.5)
                            .frame(minWidth: 80, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 16) + 16)
                    .accessibilityLabel("Skip animation")
                    .accessibilityHint("Dismisses the paper airplane and goes back")
                }
            }
        }
        .onAppear { startFold() }
    }

    // MARK: - Plane Stack

    private var planeStack: some View {
        ZStack {
            // Paper note — collapses as fold progresses
            if foldProgress < 1.0 {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .frame(width: 80, height: 96)
                    NoteLinesShape()
                        .stroke(Color(UIColor.systemGray3), lineWidth: 1.5)
                        .frame(width: 80, height: 96)
                }
                .opacity(max(0, Double(1.0 - foldProgress * 2.4)))
                .scaleEffect(y: max(0.01, 1.0 - foldProgress), anchor: .center)
                .rotation3DEffect(
                    .degrees(Double(foldProgress) * 88),
                    axis: (x: 1, y: 0, z: 0)
                )
            }

            // Airplane — fades in from mid-fold onward
            if foldProgress > 0.25 {
                let prog = min(1.0, (foldProgress - 0.25) / 0.75)

                ZStack {
                    PaperAirplaneVectorShape()
                        .fill(Color.white)
                    PaperAirplaneVectorShape()
                        .stroke(Color(UIColor.systemGray3), lineWidth: 0.75)
                    Path { p in
                        p.move(to:    CGPoint(x: 2,  y: 22))
                        p.addLine(to: CGPoint(x: 88, y: 22))
                    }
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1.0)
                }
                .frame(width: 90, height: 44)
                .opacity(Double(prog))
                .scaleEffect(Double(prog), anchor: .center)
                .rotation3DEffect(
                    .degrees((1.0 - Double(prog)) * 88),
                    axis: (x: 1, y: 0, z: 0)
                )
            }
        }
    }

    // MARK: - Gesture

    private func throwGesture(screenSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard phase == .ready || phase == .dragging else { return }
                if phase == .ready { phase = .dragging }
                planeOffset = value.translation
                // Guard against zero translation to avoid atan2(0,0) edge case
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > 1 || abs(dy) > 1 {
                    planeAngle = atan2(dy, dx) * (180 / .pi)
                }
            }
            .onEnded { value in
                guard phase == .dragging else { return }
                let vel   = value.velocity
                let speed = sqrt(vel.width * vel.width + vel.height * vel.height)

                if speed > 280 {
                    launch(velocity: vel, fromOffset: planeOffset, screenSize: screenSize)
                } else {
                    // Not fast enough — spring back
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.64)) {
                        planeOffset = .zero
                        planeAngle  = 0
                        phase       = .ready
                    }
                }
            }
    }

    // MARK: - Fold animation

    private func startFold() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.85)) {
                foldProgress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                phase = .ready
                withAnimation(.easeIn(duration: 0.45)) {
                    confirmOpacity = 1.0
                    hintOpacity    = 1.0
                }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    floatUp = true
                }
            }
        }
    }

    // MARK: - Launch
    /// Avoids simultaneous conflicting animations (source of NaN / AnimatablePair errors):
    /// dragOffset is baked into flyOffset *before* the launch animation starts,
    /// so only one CGSize value is animated at a time.
    private func launch(velocity: CGSize, fromOffset: CGSize, screenSize: CGSize) {
        phase = .flying

        let speed = sqrt(velocity.width * velocity.width + velocity.height * velocity.height)
        // Guard against zero speed (shouldn't reach here, but be safe)
        guard speed > 0 else { onComplete(); return }

        let ux       = velocity.width  / speed
        let uy       = velocity.height / speed
        let diagonal = sqrt(screenSize.width * screenSize.width + screenSize.height * screenSize.height)
        let distance = diagonal * 1.5

        // Target is relative to current position (already encoded in fromOffset)
        let targetX = fromOffset.width  + ux * distance
        let targetY = fromOffset.height + uy * distance
        let angle   = atan2(velocity.height, velocity.width) * (180 / .pi)

        let duration: Double = max(0.30, min(0.70, 680 / Double(speed)))

        // Single animation block — no competing animations on the same state
        withAnimation(.easeIn(duration: duration)) {
            planeOffset = CGSize(width: targetX, height: targetY)
            planeAngle  = angle
        }

        // Fade out using Task to avoid simultaneous withAnimation on overlapping properties
        Task {
            try? await Task.sleep(for: .seconds(duration * 0.4))
            withAnimation(.easeIn(duration: duration * 0.6)) {
                planeOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            onComplete()
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(UIColor.systemPurple).ignoresSafeArea()
        PaperAirplaneThrowView { }
    }
}
