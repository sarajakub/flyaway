import Foundation

struct MindfulnessResource: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let duration: TimeInterval
    let type: ResourceType
    let imageName: String
    let audioFileName: String?
    
    enum ResourceType: String, CaseIterable {
        case meditation = "Meditation"
        case breathwork = "Breathwork"
        case journaling = "Journaling"
        case affirmations = "Affirmations"
        
        var icon: String {
            switch self {
            case .meditation: return "sparkles"
            case .breathwork: return "wind"
            case .journaling: return "book.fill"
            case .affirmations: return "heart.text.square.fill"
            }
        }
    }
}

extension MindfulnessResource {
    static let samples = [
        MindfulnessResource(
            title: "5-Minute Breathing",
            description: "Simple breathing exercise to calm your mind",
            duration: 300,
            type: .breathwork,
            imageName: "breathwork1",
            audioFileName: "breathing_5min"
        ),
        MindfulnessResource(
            title: "Letting Go Meditation",
            description: "Release what no longer serves you",
            duration: 600,
            type: .meditation,
            imageName: "meditation1",
            audioFileName: "letting_go"
        ),
        MindfulnessResource(
            title: "Healing Affirmations",
            description: "Positive affirmations for your healing journey",
            duration: 180,
            type: .affirmations,
            imageName: "affirmations1",
            audioFileName: "healing_affirmations"
        ),
        MindfulnessResource(
            title: "Box Breathing",
            description: "4-4-4-4 breathing technique for anxiety",
            duration: 240,
            type: .breathwork,
            imageName: "breathwork2",
            audioFileName: "box_breathing"
        ),
        MindfulnessResource(
            title: "Morning Gratitude",
            description: "Start your day with gratitude journaling prompts",
            duration: 600,
            type: .journaling,
            imageName: "journaling1",
            audioFileName: nil
        ),
        MindfulnessResource(
            title: "Body Scan Meditation",
            description: "Relax and release tension from your body",
            duration: 900,
            type: .meditation,
            imageName: "meditation2",
            audioFileName: "body_scan"
        ),
        MindfulnessResource(
            title: "Self-Love Affirmations",
            description: "Build confidence and self-compassion",
            duration: 300,
            type: .affirmations,
            imageName: "affirmations2",
            audioFileName: "self_love"
        ),
        MindfulnessResource(
            title: "Evening Reflection",
            description: "Process your day through guided journaling",
            duration: 480,
            type: .journaling,
            imageName: "journaling2",
            audioFileName: nil
        ),
        MindfulnessResource(
            title: "4-7-8 Breathing",
            description: "Fall asleep faster with this calming technique",
            duration: 420,
            type: .breathwork,
            imageName: "breathwork3",
            audioFileName: "478_breathing"
        ),
        MindfulnessResource(
            title: "Mindful Walking",
            description: "Connect with the present moment through movement",
            duration: 720,
            type: .meditation,
            imageName: "meditation3",
            audioFileName: "mindful_walking"
        )
    ]
}
