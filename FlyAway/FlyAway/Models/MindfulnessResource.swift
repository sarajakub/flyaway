import Foundation

struct MindfulnessResource: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let duration: TimeInterval   // for display label only
    let type: ResourceType
    let payload: InteractivePayload

    enum ResourceType: String, CaseIterable {
        case meditation    = "Meditation"
        case breathwork    = "Breathwork"
        case journaling    = "Journaling"
        case affirmations  = "Affirmations"

        var icon: String {
            switch self {
            case .meditation:   return "sparkles"
            case .breathwork:   return "wind"
            case .journaling:   return "book.fill"
            case .affirmations: return "heart.text.square.fill"
            }
        }
    }

    // Interactive payload — drives the detail UI (no API, no audio files needed)
    enum InteractivePayload {
        /// Animated breathing circle: inhale / hold / exhale / pause seconds, N cycles
        case breathwork(inhale: Int, hold1: Int, exhale: Int, hold2: Int, cycles: Int)
        /// Scrollable journaling prompts
        case journaling(prompts: [String])
        /// Swipeable affirmation cards
        case affirmations(cards: [String])
        /// Step-by-step guided meditation text
        case meditation(steps: [String])
    }
}

// MARK: - Sample content

extension MindfulnessResource {
    static let samples: [MindfulnessResource] = [

        // BREATHWORK
        MindfulnessResource(
            title: "Box Breathing",
            description: "4-count inhale, hold, exhale, hold — the classic technique for calming your nervous system fast.",
            duration: 240,
            type: .breathwork,
            payload: .breathwork(inhale: 4, hold1: 4, exhale: 4, hold2: 4, cycles: 8)
        ),
        MindfulnessResource(
            title: "4-7-8 Breathing",
            description: "Inhale for 4, hold for 7, exhale for 8. Activates the parasympathetic system and eases anxiety.",
            duration: 300,
            type: .breathwork,
            payload: .breathwork(inhale: 4, hold1: 7, exhale: 8, hold2: 0, cycles: 6)
        ),
        MindfulnessResource(
            title: "5-Minute Calm",
            description: "Simple equal-breath pattern — 5 in, 5 out. A quick reset during a hard moment.",
            duration: 300,
            type: .breathwork,
            payload: .breathwork(inhale: 5, hold1: 0, exhale: 5, hold2: 0, cycles: 10)
        ),

        // JOURNALING
        MindfulnessResource(
            title: "Morning Gratitude",
            description: "Start your day by finding light. These prompts anchor you in what's still good.",
            duration: 600,
            type: .journaling,
            payload: .journaling(prompts: [
                "Name three things you're grateful for today — even small ones count.",
                "What's one thing about yourself you appreciate right now?",
                "Who in your life has shown up for you recently? How did that feel?",
                "What is one thing you're looking forward to, even if it's just a cup of coffee?",
                "Write about a moment this week where you felt okay. What made it that way?",
                "What would you tell a close friend who was going through what you're going through?",
                "What does healing look like for you today — not in a year, just today?"
            ])
        ),
        MindfulnessResource(
            title: "Evening Reflection",
            description: "Decompress and process your day. Let it go so it doesn't follow you into tomorrow.",
            duration: 480,
            type: .journaling,
            payload: .journaling(prompts: [
                "What was the hardest moment of today? What did it bring up?",
                "What is one thing that went better than expected today?",
                "Is there anything you're carrying from today that you want to set down?",
                "What did you need today that you didn't get? How can you give that to yourself tomorrow?",
                "Write one sentence to summarise how you felt today, without judgement.",
                "What's one thing you're choosing to release before you sleep tonight?",
                "What do you want to feel tomorrow, and what's one small thing that might help?"
            ])
        ),
        MindfulnessResource(
            title: "Letting Go",
            description: "Prompts to help you release what you're holding onto — the person, the story, the version of yourself.",
            duration: 600,
            type: .journaling,
            payload: .journaling(prompts: [
                "What are you still holding onto, even though you know it's hurting you?",
                "What did this person or situation teach you about yourself?",
                "If you let go completely, what are you afraid would happen?",
                "Write a letter to your past self — what do they need to hear?",
                "What does the version of you that has healed look like?",
                "What part of this experience are you most ready to release today?",
                "What would you do with the energy you spend thinking about this, if you reclaimed it?"
            ])
        ),

        // AFFIRMATIONS
        MindfulnessResource(
            title: "Healing Affirmations",
            description: "Gentle affirmations to carry with you as you rebuild.",
            duration: 180,
            type: .affirmations,
            payload: .affirmations(cards: [
                "I am allowed to heal at my own pace.",
                "My feelings are valid. All of them.",
                "I am not defined by what I lost.",
                "Each day, I am growing stronger than I realise.",
                "I deserve love — starting with the love I give myself.",
                "Healing is not linear, and that's okay.",
                "I am not what happened to me.",
                "I am making room for something better.",
                "My worth is not tied to anyone else's choices.",
                "I am learning to trust myself again."
            ])
        ),
        MindfulnessResource(
            title: "Self-Love Affirmations",
            description: "Rebuild confidence and self-compassion, one breath at a time.",
            duration: 300,
            type: .affirmations,
            payload: .affirmations(cards: [
                "I am worthy of kindness — especially from myself.",
                "My mistakes do not make me a mistake.",
                "I am enough, right now, exactly as I am.",
                "I choose to speak to myself with compassion.",
                "I am proud of how far I've come.",
                "I release the need to be perfect.",
                "I am learning, not failing.",
                "I trust my ability to figure things out.",
                "I give myself permission to rest.",
                "I am becoming someone I'm proud of."
            ])
        ),

        // MEDITATION
        MindfulnessResource(
            title: "Letting Go Meditation",
            description: "A guided meditation to release emotional weight and come back to yourself.",
            duration: 600,
            type: .meditation,
            payload: .meditation(steps: [
                "Find a comfortable position. Sit or lie down. Close your eyes gently.",
                "Take three slow, deep breaths. Inhale through your nose... Exhale through your mouth.",
                "Feel your body getting heavier with each exhale — let the tension release downward.",
                "Bring to mind something you've been carrying. Don't force it; let it surface naturally.",
                "Notice where you feel it in your body. Chest, throat, stomach? Just observe — don't judge.",
                "Breathe into that place. Inhale softly... and as you exhale, imagine releasing a little of the weight.",
                "Repeat to yourself: \"I am safe. I am here. This feeling is temporary.\"",
                "Picture the thing you're releasing as a leaf floating down a river. Watch it drift away.",
                "You don't have to let go of everything today. Just a little. Just enough for right now.",
                "Bring your awareness back to your breath. Feel the ground beneath you.",
                "When you're ready, gently open your eyes. Take your time."
            ])
        ),
        MindfulnessResource(
            title: "Body Scan",
            description: "Release tension stored in your body, one area at a time.",
            duration: 900,
            type: .meditation,
            payload: .meditation(steps: [
                "Lie down or sit comfortably. Let your hands rest open.",
                "Close your eyes. Take a long, slow breath in... and release.",
                "Bring attention to the top of your head. Notice any sensation — or none at all.",
                "Move slowly to your forehead and eyes. Soften them completely.",
                "Relax your jaw. Let your teeth part slightly. Unclench anything you've been holding.",
                "Your neck and shoulders — many of us store stress here. Breathe into it.",
                "Move to your chest. Feel it rise and fall. Place a hand here if it helps.",
                "Scan down to your stomach. Let it be soft. You don't have to hold it in.",
                "Your hips and lower back. Notice any tightness without trying to fix it.",
                "Down to your legs — thighs, knees, calves. Let them feel heavy and supported.",
                "Finally, your feet and toes. Feel the surface beneath them.",
                "Now breathe into your whole body at once. You've arrived. You're here.",
                "Stay as long as you need. When you're ready, gently return."
            ])
        ),
        MindfulnessResource(
            title: "5-Minute Grounding",
            description: "A quick meditation to pull you out of your head and back into the present.",
            duration: 300,
            type: .meditation,
            payload: .meditation(steps: [
                "Wherever you are, pause. You don't need to close your eyes.",
                "Take one deep breath. Just one — in... and out.",
                "Name 5 things you can see right now. Say them quietly to yourself.",
                "Name 4 things you can physically feel — the chair, your feet on the floor, air on your skin.",
                "Name 3 things you can hear in this moment.",
                "Name 2 things you can smell — or if nothing, just notice the air.",
                "Name 1 thing you're grateful for right now. Even something tiny.",
                "Take another slow breath. You are here. That's enough."
            ])
        ),
    ]
}
