import SwiftUI

struct AuthenticationView: View {
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var showingForgotPassword = false
    @State private var resetEmail = ""
    @State private var showingResetSuccess = false
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("FlyAway")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Release. Heal. Connect.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 40)
                
                VStack(spacing: 20) {
                    if isSignUp {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Display Name")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                            TextField("Your name", text: $displayName)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        TextField("you@example.com", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        SecureField("At least 6 characters", text: $password)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    if isSignUp {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm Password")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                            SecureField("Re-enter your password", text: $confirmPassword)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }
                    }
                    
                    Button(action: authenticate) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(Color.purple)
                    .cornerRadius(12)
                    .disabled(isLoading || !isFormValid)
                    .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
                    .padding(.top, 10)
                    
                    if !isSignUp {
                        Button(action: { showingForgotPassword = true }) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .underline()
                        }
                        .padding(.top, 5)
                    }
                    
                    Button(action: { 
                        isSignUp.toggle()
                        confirmPassword = ""
                        authManager.errorMessage = nil
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 30)
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordSheet(
                resetEmail: $resetEmail,
                showingSuccess: $showingResetSuccess,
                authManager: authManager
            )
        }
        .alert("Password Reset Email Sent", isPresented: $showingResetSuccess) {
            Button("OK") {
                showingForgotPassword = false
                resetEmail = ""
            }
        } message: {
            Text("Check your email for instructions to reset your password.")
        }
    }
    
    var isFormValid: Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        
        if isSignUp {
            guard !displayName.isEmpty else { return false }
            guard password.count >= 6 else { return false }
            guard password == confirmPassword else { return false }
        }
        
        return true
    }
    
    private func authenticate() {
        authManager.errorMessage = nil
        isLoading = true
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            if isSignUp {
                await authManager.signUp(email: trimmedEmail, password: trimmedPassword, displayName: displayName)
            } else {
                await authManager.signIn(email: trimmedEmail, password: trimmedPassword)
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct ForgotPasswordSheet: View {
    @Binding var resetEmail: String
    @Binding var showingSuccess: Bool
    @ObservedObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your email address and we'll send you instructions to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                TextField("Email", text: $resetEmail)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal)
                
                Button(action: sendResetEmail) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Reset Link")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.purple)
                .cornerRadius(12)
                .disabled(isLoading || resetEmail.isEmpty)
                .opacity((isLoading || resetEmail.isEmpty) ? 0.6 : 1.0)
                .padding(.horizontal)
                
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private func sendResetEmail() {
        isLoading = true
        authManager.errorMessage = nil
        
        let trimmedEmail = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            await authManager.resetPassword(email: trimmedEmail)
            
            await MainActor.run {
                isLoading = false
                if authManager.errorMessage == nil {
                    showingSuccess = true
                }
            }
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .foregroundColor(.black)
            .background(Color.white.opacity(0.95))
            .cornerRadius(12)
            .accentColor(.purple)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}
