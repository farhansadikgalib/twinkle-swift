//
//  AuthenticationService.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let db = Firestore.firestore()
    private let userDefaults = UserDefaultsManager.shared
    
    private init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let firebaseUser = Auth.auth().currentUser {
            isAuthenticated = true
            fetchUserData(userId: firebaseUser.uid)
        } else if userDefaults.isLoggedIn, let userId = userDefaults.userId {
            // User was logged in before, try to restore session
            isAuthenticated = true
            fetchUserData(userId: userId)
        } else {
            isAuthenticated = false
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let userId = authResult.user.uid
            
            // Update user online status
            try await updateUserOnlineStatus(userId: userId, isOnline: true)
            
            // Fetch user data
            fetchUserData(userId: userId)
            
            // Save to UserDefaults
            if let user = currentUser {
                userDefaults.saveUserSession(userId: user.id, email: user.email, name: user.displayName)
            }
            
            isAuthenticated = true
        } catch {
            throw error
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let userId = authResult.user.uid
            
            // Create user document in Firestore
            let newUser = User(
                id: userId,
                email: email,
                displayName: displayName,
                isOnline: true,
                lastSeen: Date()
            )
            
            try await db.collection("users").document(userId).setData([
                "id": newUser.id,
                "email": newUser.email,
                "displayName": newUser.displayName,
                "isOnline": newUser.isOnline,
                "lastSeen": newUser.lastSeen.timeIntervalSince1970
            ])
            
            currentUser = newUser
            userDefaults.saveUserSession(userId: userId, email: email, name: displayName)
            isAuthenticated = true
        } catch {
            throw error
        }
    }
    
    func signOut() async throws {
        if let userId = currentUser?.id {
            try await updateUserOnlineStatus(userId: userId, isOnline: false)
        }
        
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
        userDefaults.clearUserSession()
    }
    
    func fetchUserData(userId: String) {
        db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            Task { @MainActor in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let user = try JSONDecoder().decode(User.self, from: jsonData)
                    self.currentUser = user
                } catch {
                    print("Error decoding user: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateUserOnlineStatus(userId: String, isOnline: Bool) async throws {
        try await db.collection("users").document(userId).updateData([
            "isOnline": isOnline,
            "lastSeen": Date().timeIntervalSince1970
        ])
    }
    
    func updateFCMToken(_ token: String) async throws {
        guard let userId = currentUser?.id else { return }
        
        try await db.collection("users").document(userId).updateData([
            "fcmToken": token
        ])
        
        userDefaults.fcmToken = token
    }
}
