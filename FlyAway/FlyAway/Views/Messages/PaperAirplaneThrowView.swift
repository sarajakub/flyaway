import SwiftUI

// MARK: - Paper Airplane Vector Shape
/// Classic delta-wing dart, pointing right. All coordinates are proportional to bounds.
struct PaperAirplaneVectorShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        let nose    = CGPoint(x: w,        y: h * 0.50)  // rightmost tip
        let topBack = CGPoint(x: 0,        y: 0        )  // top-left corner
        let botBack = CGPoint(x: 0,        y: h        )  // bottom-left corner
        let topFold = CGPoint(x: w * 0.52, y: h * 0.24)  // top wing meets body
        let botFold = CGPoint(x: w * 0.52, y: h * 0.76)  // bottom wing meets body
        let topGrip = CGPoint(x: w * 0.18, y: h * 0.43)  // top of center channel
        let botGrip = CGPoint(x: w * 0.18, y: h * 0.57)  // bottom of center channel

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
/// Horizontal strokes that simulate handwritten text on a folded note.
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

// MARK: - Internal Throw Phase
private enum ThrowPhase {
    case folding    // paper auto-folds into airplane
    case ready      // airplane waiting for swipe
    case dragging   // finger is actively on screen
    case flying     // released with velocity
}

// MARK: - Paper Airplane Throw View
/// Full-screen overlay that plays the paper-fold → swipe-to-throw animation.
/// Call `onComplete` when the plane exits the screen (or the user taps Skip).
struct PaperAirplaneThrowView: View {
    let onComplete: () -> Void

    @State private var phase: ThrowPhase = .folding
    @State private var foldProgress: CGFloat = 0.0

    @State private var dragOffset: CGSize = .zero
    @State private var planeAngle: Double = 0.0

    @State private var flyOffset: CGSize = .zero
    @State private var flyOpacity: Double = 1.0

    @State private var floatUp: Bool = false
    @State private var hintOpacity: Double = 0.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Background dim ──────────────────────────────────────────
                Color.black.opacity(0.62)
                    .ignoresSafeArea()

                // ── Labels ──────────────────────────────────────────────────
                VStack(spacing: 6) {
                    Spacer()

                    Text("Message sent")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.55))

                    Text(phase == .dragging ? "" : "Swipe to release")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(hintOpacity))
                        .animation(.easeInOut(duration: 0.25), value: phase)

                    Spacer()
                        .frame(height: geo.size.height * 0.20)
                }

                // ── Paper / Airplane ────────────────────────────────────────
                planeStack
                    .rotationEffect(.degrees(planeAngle))
                    .offset(
                        x: flyOffset.width  + dragOffset.width,
                        y: flyOffset.height + dragOffset.height
                            + (phase == .ready ? (floatUp ? -7 : 7) : 0)
                    )
                    .opacity(flyOpacity)
                    .gesture(throwGesture(screenSize: geo.size))
                    .accessibilityLabel("Paper airplane. Swipe in any direction to release.")

                // ── Skip button ─────────────────────────────────────────────
                VStack {
                    Spacer()
                    Button("Skip") { onComplete() }
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.30))
                        .padding(.bottom, 36)
                }
            }
        }
        .onAppear { startFold() }
    }

    // MARK: - Plane Stack view

    private var planeStack: some View {
        ZStack {
            // Paper note — fades out as fold progresses
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

            // Paper airplane — appears from mid-fold onward
            if foldProgress > 0.25 {
                let prog = CGFloat(min(1.0, Double((foldProgress - 0.25) / 0.75)))

                ZStack {
                    PaperAirplaneVectorShape()
                        .fill(Color.white)
                    PaperAirplaneVectorShape()
                        .stroke(Color(UIColor.systemGray3), lineWidth: 0.75)
                    // Center spine / fold crease
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

    // MARK: - Drag gesture

    private func throwGesture(screenSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard phase == .ready || phase == .dragging else { return }
                if phase == .ready { phase = .dragging }
                dragOffset = value.translation
                // Rotate plane to face the throw direction
                let angle = atan2(value.translation.height, value.translation.width)
                planeAngle = angle * (180 / .pi)
            }
            .onEnded { value in
                guard phase == .dragging else { return }
                let vel   = value.velocity
                let speed = sqrt(vel.width * vel.width + vel.height * vel.height)

                if speed > 280 {
                    launch(velocity: vel, screenSize: screenSize)
                } else {
                    // Not fast enough — snap back with a gentle spring
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.64)) {
                        dragOffset = .zero
                        planeAngle = 0
                        phase      = .ready
                    }
                }
            }
    }

    // MARK: - Animation helpers

    private func startFold() {
        // Small initial pause so the overlay settles before animating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            withAnimation(.easeInOut(duration: 0.88)) {
                foldProgress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                phase = .ready
                startIdleFloat()
                withAnimation(.easeIn(duration: 0.5)) {
                    hintOpacity = 0.85
                }
            }
        }
    }

    private func startIdleFloat() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            floatUp = true
        }
    }

    private func launch(velocity: CGSize, screenSize: CGSize) {
        phase = .flying

        let speed    = sqrt(velocity.width * velocity.width + velocity.height * velocity.height)
        let ux       = velocity.width  / speed
        let uy       = velocity.height / speed
        let diagonal = sqrt(screenSize.width * screenSize.width + screenSize.height * screenSize.height)
        let distance = diagonal * 1.45  // overshoot to guarantee it exits

        let targetX  = dragOffset.width  + ux * distance
        let targetY  = dragOffset.height + uy * distance
        let angle    = atan2(velocity.height, velocity.width) * (180 / .pi)

        // Faster swipes produce shorter animation durations
        let duration: Double = max(0.28, min(0.72, 680 / Double(speed)))

        withAnimation(.easeIn(duration: duration)) {
            flyOffset  = CGSize(width: targetX, height: targetY)
            planeAngle = angle
            dragOffset = .zero
        }
        withAnimation(.easeIn(duration: duration * 0.65).delay(duration * 0.35)) {
            flyOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.12) {
            onComplete()
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.purple.ignoresSafeArea()
        PaperAirplaneThrowView { }
    }
}
