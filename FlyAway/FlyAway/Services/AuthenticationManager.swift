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
                AnalyticsManager.logSignUp()
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
                AnalyticsManager.logSignIn()
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

    /// Permanently deletes all user data from Firestore and the Firebase Auth account.
    /// Collections erased: users, thoughts, messages, thoughtActivities, savedThoughts,
    /// moodEntries, milestones, reactions.
    func deleteAccount() async {
        guard let user = auth.currentUser else {
            await MainActor.run { self.errorMessage = "Not signed in" }
            return
        }
        let uid = user.uid

        do {
            // 1. Delete user-owned Firestore documents in parallel
            async let _ = deleteCollection("thoughts",          field: "userId",    value: uid)
            async let _ = deleteCollection("messages",          field: "userId",    value: uid)
            async let _ = deleteCollection("thoughtActivities", field: "userId",    value: uid)
            async let _ = deleteCollection("savedThoughts",     field: "userId",    value: uid)
            async let _ = deleteCollection("moodEntries",       field: "userId",    value: uid)
            async let _ = deleteCollection("milestones",        field: "userId",    value: uid)
            async let _ = deleteCollection("reactions",         field: "userId",    value: uid)

            // 2. Delete user profile document
            try await db.collection("users").document(uid).delete()

            // 3. Delete Firebase Auth account
            try await user.delete()

            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
                AnalyticsManager.logAccountDeleted()
                print("✅ Account deleted for UID: \(uid)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Account deletion failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Private helpers

    /// Deletes all documents in `collection` where `field` == `value`, in batches of 100.
    private func deleteCollection(_ collection: String, field: String, value: String) async {
        do {
            let snapshot = try await db.collection(collection)
                .whereField(field, isEqualTo: value)
                .getDocuments()
            let batch = db.batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
        } catch {
            print("⚠️ Could not delete \(collection) for user: \(error.localizedDescription)")
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
