import SwiftUI

struct DailyMoodCheckIn: View {
    @EnvironmentObject var moodManager: MoodManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedMood: Int?
    @State private var showNoteOption = false
    @State private var showNoteInput = false
    @State private var noteText = ""
    @FocusState private var isNoteFocused: Bool
    @State private var isSaving = false
    
    let moods: [(emoji: String, label: String, value: Int)] = [
        ("😢", "Very Bad", 1),
        ("😔", "Bad", 2),
        ("😐", "Okay", 3),
        ("🙂", "Good", 4),
        ("😊", "Great", 5)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("How are you feeling today?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Track your emotional journey")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Mood Selection
                    VStack(spacing: 20) {
                        ForEach(moods, id: \.value) { mood in
                            Button {
                                selectedMood = mood.value
                                withAnimation {
                                    showNoteOption = true
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    Text(mood.emoji)
                                        .font(.system(size: 40))
                                    
                                    Text(mood.label)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedMood == mood.value {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.purple)
                                    }
                                }
                                .padding()
                                .background(
                                    selectedMood == mood.value ?
                                    Color.purple.opacity(0.1) :
                                    Color(.systemGray6)
                                )
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Note Option
                    if showNoteOption && !showNoteInput {
                        VStack(spacing: 16) {
                            Text("Want to add context?")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                Button {
                                    Task {
                                        await saveMood()
                                    }
                                } label: {
                                    Text("No, just save")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                
                                Button {
                                    withAnimation {
                                        showNoteInput = true
                                        isNoteFocused = true
                                    }
                                } label: {
                                    Text("Yes, add note")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.purple)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .transition(.opacity)
                    }
                    
                    // Note Input
                    if showNoteInput {
                        VStack(spacing: 16) {
                            Text("What's on your mind?")
                                .font(.headline)
                            
                            TextEditor(text: $noteText)
                                .focused($isNoteFocused)
                                .frame(height: 120)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                            
                            Button {
                                Task {
                                    await saveMood()
                                }
                            } label: {
                                Text("Save")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Daily Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveMood() async {
        guard let mood = selectedMood, !isSaving else { return }
        isSaving = true
        let note = noteText.isEmpty ? nil : noteText
        await moodManager.saveMood(mood: mood, note: note)
        await MainActor.run {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss()
        }
    }
}

#Preview {
    DailyMoodCheckIn()
        .environmentObject(MoodManager())
}
