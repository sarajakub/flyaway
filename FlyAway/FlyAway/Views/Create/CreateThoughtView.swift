import SwiftUI

struct CreateThoughtView: View {
    @State private var thoughtText = ""
    @State private var selectedCategory: Thought.ThoughtCategory = .reflection
    @State private var isPublic = true
    @State private var sendToEther = false
    @State private var keepForDays: Int?
    @State private var showingSuccess = false
    @State private var showingError = false
    
    @EnvironmentObject var thoughtManager: ThoughtManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        
                        Text("Release Your Thoughts")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Write or speak what's on your mind")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    VStack(alignment: .leading) {
                        Text("Your Thought")
                            .font(.headline)
                        
                        TextEditor(text: $thoughtText)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(Thought.ThoughtCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    
                    VStack(spacing: 16) {
                        Toggle("Make Public", isOn: $isPublic)
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                        
                        Toggle("Send to Ether (disappear immediately)", isOn: $sendToEther)
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                        
                        if !sendToEther {
                            VStack(alignment: .leading) {
                                Text("Keep for:")
                                    .font(.subheadline)
                                
                                Picker("Duration", selection: $keepForDays) {
                                    Text("Forever").tag(nil as Int?)
                                    Text("1 Day").tag(1 as Int?)
                                    Text("7 Days").tag(7 as Int?)
                                    Text("30 Days").tag(30 as Int?)
                                    Text("90 Days").tag(90 as Int?)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button(action: createThought) {
                        HStack {
                            Image(systemName: sendToEther ? "paperplane.fill" : "square.and.arrow.down")
                            Text(sendToEther ? "Release to Ether" : "Save Thought")
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
                    .disabled(thoughtText.isEmpty)
                    .opacity(thoughtText.isEmpty ? 0.6 : 1.0)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .alert("Thought Released", isPresented: $showingSuccess) {
            Button("OK") {
                thoughtText = ""
                selectedCategory = .reflection
                sendToEther = false
                keepForDays = nil
            }
        } message: {
            Text(sendToEther ? "Your thought has been released into the ether." : "Your thought has been saved successfully!")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(thoughtManager.errorMessage ?? "Failed to save thought")
        }
    }
    
    private func createThought() {
        Task {
            await thoughtManager.createThought(
                content: thoughtText,
                isPublic: isPublic,
                category: selectedCategory,
                sendToEther: sendToEther,
                keepForDays: keepForDays
            )
            
            await MainActor.run {
                if thoughtManager.errorMessage != nil {
                    showingError = true
                } else {
                    showingSuccess = true
                }
            }
        }
    }
}

struct CategoryButton: View {
    let category: Thought.ThoughtCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(category.emoji)
                    .font(.title)
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.purple.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateThoughtView()
        .environmentObject(ThoughtManager())
}
