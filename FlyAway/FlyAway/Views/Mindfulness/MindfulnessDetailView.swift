import SwiftUI

struct MindfulnessDetailView: View {
    let resource: MindfulnessResource
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 250)
                    
                    VStack(spacing: 16) {
                        Image(systemName: resource.type.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text(resource.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                .cornerRadius(20)
                .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline)
                    
                    Text(resource.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                HStack {
                    Image(systemName: "clock")
                    Text("Duration: \(formatDuration(resource.duration))")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 20) {
                    ProgressView(value: progress, total: 1.0)
                        .tint(.purple)
                    
                    HStack {
                        Text(formatTime(progress * resource.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatTime(resource.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Benefits")
                        .font(.headline)
                    
                    ForEach(benefits, id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.purple)
                            Text(benefit)
                                .font(.subheadline)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var benefits: [String] {
        switch resource.type {
        case .meditation:
            return [
                "Reduces stress and anxiety",
                "Improves emotional well-being",
                "Enhances self-awareness",
                "Promotes better sleep"
            ]
        case .breathwork:
            return [
                "Calms the nervous system",
                "Reduces anxiety quickly",
                "Improves focus and clarity",
                "Helps manage panic attacks"
            ]
        case .journaling:
            return [
                "Process emotions effectively",
                "Track healing progress",
                "Gain clarity and insight",
                "Release pent-up feelings"
            ]
        case .affirmations:
            return [
                "Builds self-confidence",
                "Rewires negative thought patterns",
                "Promotes positive mindset",
                "Strengthens resilience"
            ]
        }
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes) minutes"
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    NavigationView {
        MindfulnessDetailView(resource: MindfulnessResource.samples[0])
    }
}
