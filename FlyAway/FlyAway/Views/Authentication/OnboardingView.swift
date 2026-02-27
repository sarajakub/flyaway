import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "paperplane.fill",
            iconColors: [Color.purple, Color.blue],
            title: "Welcome to FlyAway",
            subtitle: "Release. Heal. Connect.",
            description: "FlyAway is your safe space to let go of the things weighing on you — grief, anxiety, heartbreak — and find peace at your own pace."
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            iconColors: [Color.indigo, Color.purple],
            title: "Release Your Thoughts",
            subtitle: "Write. Release. Let go.",
            description: "Journal freely — send your thoughts into the ether, set them to expire, or keep them privately. No judgment, just healing."
        ),
        OnboardingPage(
            icon: "person.3.fill",
            iconColors: [Color.pink, Color.orange],
            title: "You're Not Alone",
            subtitle: "A community that gets it.",
            description: "Read anonymous thoughts from others on the same journey. React, save, and feel seen — without ever having to share your name."
        ),
        OnboardingPage(
            icon: "envelope.circle.fill",
            iconColors: [Color.teal, Color.blue],
            title: "Messages to the Past",
            subtitle: "Say the unsaid.",
            description: "Write messages to people you can no longer reach — loved ones lost, relationships ended, past versions of yourself. It can help."
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient that shifts with current page
            LinearGradient(
                colors: pages[currentPage].iconColors.map { $0.opacity(0.25) } + [Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {

                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .accessibilityHint("Jumps to the last page")
                    } else {
                        // Spacer to keep layout consistent
                        Text("")
                            .padding()
                    }
                }

                // TabView for swipe between pages
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicator dots — hidden from VoiceOver (TabView navigation is accessible)
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.purple : Color.secondary.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .accessibilityHidden(true)
                .padding(.bottom, 24)

                // Action button
                Button(action: advance) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: pages[currentPage].iconColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: pages[currentPage].iconColors.first?.opacity(0.4) ?? .purple.opacity(0.4),
                                radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }

    private func advance() {
        if !UIAccessibility.isReduceMotionEnabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }

        if currentPage < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPage += 1
            }
        } else {
            withAnimation {
                hasSeenOnboarding = true
            }
        }
    }
}

// MARK: - Supporting Types

struct OnboardingPage {
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: page.iconColors.first?.opacity(0.4) ?? .purple.opacity(0.4),
                            radius: 20, x: 0, y: 8)

                Image(systemName: page.icon)
                    .font(.system(size: 52))
                    .foregroundColor(.white)
            }

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.headline)
                    .foregroundColor(page.iconColors.first ?? .purple)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
