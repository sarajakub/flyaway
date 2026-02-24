import SwiftUI

struct EditMilestoneSheet: View {
    let milestone: Milestone

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var milestoneManager: MilestoneManager

    @State private var title: String
    @State private var eventDate: Date
    @State private var showingError = false

    init(milestone: Milestone) {
        self.milestone = milestone
        _title = State(initialValue: milestone.title)
        _eventDate = State(initialValue: milestone.eventDate)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Milestone Title", text: $title)
                        .autocorrectionDisabled()

                    DatePicker("Event Date", selection: $eventDate, displayedComponents: .date)
                } header: {
                    Text("Edit Milestone")
                } footer: {
                    Text("Changing the date updates the day counter immediately.")
                        .font(.caption)
                }
            }
            .navigationTitle("Edit Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(milestoneManager.errorMessage ?? "Could not save changes.")
            }
        }
    }

    private func save() async {
        var updated = milestone
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.eventDate = eventDate

        await milestoneManager.updateMilestone(updated)

        if milestoneManager.errorMessage != nil {
            showingError = true
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss()
        }
    }
}

#Preview {
    EditMilestoneSheet(milestone: Milestone(
        userId: "123",
        title: "Breakup Date",
        eventDate: Calendar.current.date(byAdding: .day, value: -45, to: Date())!,
        createdAt: Date()
    ))
    .environmentObject(MilestoneManager())
}
