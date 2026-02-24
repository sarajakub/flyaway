import SwiftUI

struct MilestoneCard: View {
    let milestone: Milestone
    @EnvironmentObject var milestoneManager: MilestoneManager
    @State private var showingDeleteAlert = false
    @State private var showingEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.timeSinceText)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text(milestone.eventDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 220)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(16)
        .sheet(isPresented: $showingEdit) {
            EditMilestoneSheet(milestone: milestone)
        }
        .alert("Delete Milestone?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await milestoneManager.deleteMilestone(milestone)
                }
            }
        } message: {
            Text("This will permanently delete this milestone.")
        }
    }
}
