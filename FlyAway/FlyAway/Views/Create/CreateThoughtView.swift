import SwiftUI

struct CreateThoughtView: View {
    var isDismissable: Bool = false

    @State private var thoughtText = ""
    @State private var selectedCategory: Thought.ThoughtCategory = .reflection
    @State private var isPublic = true
    @State private var postAsAnonymous = true
    @State private var sendToEther = false
    @State private var keepForDays: Int?
    @State private var showingSuccess = false
    @State private var showingError = false
    @FocusState private var isTextFieldFocused: Bool
    
    @EnvironmentObject var thoughtManager: ThoughtManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Close button — only visible when presented as a sheet
                if isDismissable {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }

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
                        .focused($isTextFieldFocused)
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
                    Toggle("Share with Community", isOn: $isPublic)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                    
                    if isPublic {
                        Toggle("Post Anonymously", isOn: $postAsAnonymous)
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                    }
                    
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
                        Image(systemName: sendToEther ? "paperplane.fill" : "square.and.arrow.up")
                        Text(sendToEther ? "Release to Ether" : "Share Thought")
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
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            isTextFieldFocused = false
        }
        .alert("Thought Shared", isPresented: $showingSuccess) {
            Button("OK") {
                thoughtText = ""
                selectedCategory = .reflection
                sendToEther = false
                keepForDays = nil
                postAsAnonymous = true
                isTextFieldFocused = false
            }
        } message: {
            Text(sendToEther ? "Your thought has been released into the ether." : "Your thought has been shared successfully!")
        }
        .onChange(of: showingSuccess) { _, newValue in
            if newValue {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
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
                keepForDays: keepForDays,
                postAsAnonymous: postAsAnonymous
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
