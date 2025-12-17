//
//  UserDefaultsManager.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import Foundation

@MainActor
class UserDefaultsManager: ObservableObject {
    static let shared = UserDefaultsManager()
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let isLoggedIn = "isLoggedIn"
        static let userId = "userId"
        static let userEmail = "userEmail"
        static let userName = "userName"
        static let fcmToken = "fcmToken"
    }
    
    @Published var isLoggedIn: Bool {
        didSet {
            userDefaults.set(isLoggedIn, forKey: Keys.isLoggedIn)
        }
    }
    
    @Published var userId: String? {
        didSet {
            userDefaults.set(userId, forKey: Keys.userId)
        }
    }
    
    @Published var userEmail: String? {
        didSet {
            userDefaults.set(userEmail, forKey: Keys.userEmail)
        }
    }
    
    @Published var userName: String? {
        didSet {
            userDefaults.set(userName, forKey: Keys.userName)
        }
    }
    
    var fcmToken: String? {
        get {
            userDefaults.string(forKey: Keys.fcmToken)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.fcmToken)
        }
    }
    
    private init() {
        self.isLoggedIn = userDefaults.bool(forKey: Keys.isLoggedIn)
        self.userId = userDefaults.string(forKey: Keys.userId)
        self.userEmail = userDefaults.string(forKey: Keys.userEmail)
        self.userName = userDefaults.string(forKey: Keys.userName)
    }
    
    func saveUserSession(userId: String, email: String, name: String) {
        self.isLoggedIn = true
        self.userId = userId
        self.userEmail = email
        self.userName = name
    }
    
    func clearUserSession() {
        self.isLoggedIn = false
        self.userId = nil
        self.userEmail = nil
        self.userName = nil
        self.fcmToken = nil
    }
}
