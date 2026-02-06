import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let firebaseUser = auth.currentUser {
            isAuthenticated = true
            fetchUserData(uid: firebaseUser.uid)
        } else {
            isAuthenticated = false
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Update Firebase Auth profile with displayName
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            print("✅ Firebase Auth displayName set to: \(displayName)")
            
            let newUser = AppUser(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                bio: nil,
                createdAt: Date(),
                followers: [],
                following: [],
                isAnonymous: false,
                profileImageURL: nil
            )
            
            try db.collection("users").document(result.user.uid).setData(from: newUser)
            
            await MainActor.run {
                self.currentUser = newUser
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            fetchUserData(uid: result.user.uid)
            
            await MainActor.run {
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func resetPassword(email: String) async {
        do {
            try await auth.sendPasswordReset(withEmail: email)
            await MainActor.run {
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func fetchUserData(uid: String) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            if let user = try? snapshot?.data(as: AppUser.self) {
                self.currentUser = user
            }
        }
    }
}
