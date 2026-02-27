import SwiftUI

struct NewMessageSheet: View {
    @ObservedObject var messageManager: MessageManager
    @Environment(\.dismiss) var dismiss
    
    @State private var recipientName = ""
    @State private var messageText = ""
    @State private var isSending = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case recipient, message
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("New Message")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Send a message to someone you can no longer reach")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("To:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Name", text: $recipientName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .focused($focusedField, equals: .recipient)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .message
                        }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $messageText)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .message)
                }
                .padding(.horizontal)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { focusedField = nil }
                    }
                }
                
                Button(action: sendMessage) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Message")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
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
                .disabled(isSending || recipientName.isEmpty || messageText.isEmpty)
                .opacity((isSending || recipientName.isEmpty || messageText.isEmpty) ? 0.6 : 1.0)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
            .onAppear {
                // Auto-focus recipient field when sheet appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .recipient
                }
            }
        }
    }
    
    private func sendMessage() {
        isSending = true
        focusedField = nil

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        Task {
            await messageManager.sendMessage(to: recipientName, content: messageText)

            await MainActor.run {
                dismiss()
            }
        }
    }
}

#Preview {
    NewMessageSheet(messageManager: MessageManager())
}
