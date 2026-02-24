import SwiftUI

struct AddMilestoneSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var milestoneManager: MilestoneManager
    
    @State private var title = ""
    @State private var eventDate = Date()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Milestone Title", text: $title)
                        .autocorrectionDisabled()
                    
                    DatePicker("Event Date", selection: $eventDate, displayedComponents: .date)
                } header: {
                    Text("Milestone Details")
                } footer: {
                    Text("Examples: \"Last time I texted them\", \"Breakup date\", \"Started therapy\"")
                        .font(.caption)
                }
            }
            .navigationTitle("Add Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await addMilestone()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addMilestone() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Please enter a title for this milestone"
            showingError = true
            return
        }
        
        await milestoneManager.createMilestone(title: trimmedTitle, eventDate: eventDate)
        
        if let error = milestoneManager.errorMessage {
            errorMessage = error
            showingError = true
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss()
        }
    }
}

#Preview {
    AddMilestoneSheet()
        .environmentObject(MilestoneManager())
}
