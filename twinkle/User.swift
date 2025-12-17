//
//  User.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    var id: String
    var email: String
    var displayName: String
    var profileImageURL: String?
    var fcmToken: String?
    var isOnline: Bool
    var lastSeen: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case profileImageURL
        case fcmToken
        case isOnline
        case lastSeen
    }
    
    init(id: String, email: String, displayName: String, profileImageURL: String? = nil, fcmToken: String? = nil, isOnline: Bool = false, lastSeen: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.fcmToken = fcmToken
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        isOnline = try container.decodeIfPresent(Bool.self, forKey: .isOnline) ?? false
        
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
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encodeIfPresent(fcmToken, forKey: .fcmToken)
        try container.encode(isOnline, forKey: .isOnline)
        try container.encode(lastSeen.timeIntervalSince1970, forKey: .lastSeen)
    }
}
