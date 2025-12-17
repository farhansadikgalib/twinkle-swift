//
//  Conversation.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import Foundation

struct Conversation: Identifiable, Codable, Equatable {
    var id: String
    var participantIds: [String]
    var lastMessage: String
    var lastMessageTimestamp: Date
    var unreadCount: Int
    var otherUser: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case participantIds
        case lastMessage
        case lastMessageTimestamp
        case unreadCount
    }
    
    init(id: String, participantIds: [String], lastMessage: String, lastMessageTimestamp: Date, unreadCount: Int = 0, otherUser: User? = nil) {
        self.id = id
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.unreadCount = unreadCount
        self.otherUser = otherUser
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        participantIds = try container.decode([String].self, forKey: .participantIds)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        unreadCount = try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
        
        if let timestamp = try? container.decode(Double.self, forKey: .lastMessageTimestamp) {
            lastMessageTimestamp = Date(timeIntervalSince1970: timestamp)
        } else {
            lastMessageTimestamp = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(participantIds, forKey: .participantIds)
        try container.encode(lastMessage, forKey: .lastMessage)
        try container.encode(lastMessageTimestamp.timeIntervalSince1970, forKey: .lastMessageTimestamp)
        try container.encode(unreadCount, forKey: .unreadCount)
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
}
