//
//  UserModel.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    var id: String
    var email: String
    var displayName: String
    var isOnline: Bool
    var lastSeen: Date
    var fcmToken: String?
    var photoURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case isOnline
        case lastSeen
        case fcmToken
        case photoURL
    }
    
    init(id: String, email: String, displayName: String, isOnline: Bool, lastSeen: Date, fcmToken: String? = nil, photoURL: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.fcmToken = fcmToken
        self.photoURL = photoURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        isOnline = try container.decodeIfPresent(Bool.self, forKey: .isOnline) ?? false
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        
        if let timestamp = try? container.decode(Double.self, forKey: .lastSeen) {
            lastSeen = Date(timeIntervalSince1970: timestamp)
        } else {
            lastSeen = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(isOnline, forKey: .isOnline)
        try container.encode(lastSeen.timeIntervalSince1970, forKey: .lastSeen)
        try container.encodeIfPresent(fcmToken, forKey: .fcmToken)
        try container.encodeIfPresent(photoURL, forKey: .photoURL)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
