import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FeedbackSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackType: FeedbackType = .bug
    @State private var feedbackText = ""
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var isSubmitting = false
    @FocusState private var isTextFieldFocused: Bool
    
    enum FeedbackType: String, CaseIterable {
        case bug = "Bug Report"
        case feature = "Feature Request"
        case improvement = "Improvement"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .bug: return "ladybug.fill"
            case .feature: return "lightbulb.fill"
            case .improvement: return "star.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .bug: return .red
            case .feature: return .blue
            case .improvement: return .green
            case .other: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        
                        Text("Send Feedback")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Help us make FlyAway better")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Feedback Type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Type")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(FeedbackType.allCases, id: \.self) { type in
                                Button {
                                    feedbackType = type
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.title2)
                                            .foregroundColor(feedbackType == type ? type.color : .secondary)
                                        
                                        Text(type.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(feedbackType == type ? .primary : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(feedbackType == type ? type.color.opacity(0.1) : Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(feedbackType == type ? type.color : Color.clear, lineWidth: 2)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Feedback Text
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        TextEditor(text: $feedbackText)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                            .focused($isTextFieldFocused)
                        
                        Text("Please describe your \(feedbackType == .bug ? "bug" : "suggestion") in detail")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Submit Button
                    Button(action: submitFeedback) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Submit Feedback")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                    .opacity(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                }
                .padding()
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Feedback Sent", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for helping us improve FlyAway!")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text("Failed to send feedback. Please try again.")
            }
        }
    }
    
    private func submitFeedback() {
        let trimmedText = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isSubmitting = true
        
        Task {
            let userId = Auth.auth().currentUser?.uid ?? "anonymous"
            let userEmail = Auth.auth().currentUser?.email ?? "unknown"
            
            let feedback: [String: Any] = [
                "userId": userId,
                "userEmail": userEmail,
                "type": feedbackType.rawValue,
                "feedback": trimmedText,
                "createdAt": Timestamp(date: Date()),
                "platform": "iOS"
            ]
            
            do {
                try await Firestore.firestore().collection("feedback").addDocument(data: feedback)
                
                await MainActor.run {
                    isSubmitting = false
                    showingSuccess = true
                    
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    FeedbackSheet()
}
