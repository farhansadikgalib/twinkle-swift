//
//  ChatService.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()
    
    @Published var conversations: [Conversation] = []
    @Published var messages: [Message] = []
    @Published var users: [User] = []
    
    private let db = Firestore.firestore()
    private var messagesListener: ListenerRegistration?
    private var conversationsListener: ListenerRegistration?
    
    private init() {}
    
    // MARK: - Fetch Users
    func fetchUsers(excludingUserId: String) {
        db.collection("users")
            .whereField("id", isNotEqualTo: excludingUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching users: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    self.users = documents.compactMap { document -> User? in
                        let data = document.data()
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: data)
                            return try JSONDecoder().decode(User.self, from: jsonData)
                        } catch {
                            print("Error decoding user: \(error.localizedDescription)")
                            return nil
                        }
                    }
                }
            }
    }
    
    // MARK: - Fetch Conversations
    func fetchConversations(userId: String) {
        conversationsListener = db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching conversations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    var conversations: [Conversation] = []
                    
                    for document in documents {
                        let data = document.data()
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: data)
                            var conversation = try JSONDecoder().decode(Conversation.self, from: jsonData)
                            
                            // Fetch other user info
                            if let otherUserId = conversation.participantIds.first(where: { $0 != userId }) {
                                let userDoc = try await self.db.collection("users").document(otherUserId).getDocument()
                                if let userData = userDoc.data() {
                                    let userJsonData = try JSONSerialization.data(withJSONObject: userData)
                                    conversation.otherUser = try JSONDecoder().decode(User.self, from: userJsonData)
                                }
                            }
                            
                            conversations.append(conversation)
                        } catch {
                            print("Error decoding conversation: \(error.localizedDescription)")
                        }
                    }
                    
                    self.conversations = conversations
                }
            }
    }
    
    // MARK: - Fetch Messages
    func fetchMessages(conversationId: String) {
        messagesListener?.remove()
        
        messagesListener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    self.messages = documents.compactMap { document -> Message? in
                        let data = document.data()
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: data)
                            return try JSONDecoder().decode(Message.self, from: jsonData)
                        } catch {
                            print("Error decoding message: \(error.localizedDescription)")
                            return nil
                        }
                    }
                }
            }
    }
    
    // MARK: - Send Message
    func sendMessage(text: String, senderId: String, senderName: String, receiverId: String, receiverToken: String?) async throws {
        let conversationId = getConversationId(userId1: senderId, userId2: receiverId)
        let message = Message(
            senderId: senderId,
            senderName: senderName,
            receiverId: receiverId,
            text: text,
            timestamp: Date()
        )
        
        let messageData: [String: Any] = [
            "id": message.id,
            "senderId": message.senderId,
            "senderName": message.senderName,
            "receiverId": message.receiverId,
            "text": message.text,
            "timestamp": message.timestamp.timeIntervalSince1970,
            "isRead": message.isRead
        ]
        
        // Add message to conversation
        try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(message.id)
            .setData(messageData)
        
        // Update or create conversation
        let conversationData: [String: Any] = [
            "id": conversationId,
            "participantIds": [senderId, receiverId],
            "lastMessage": text,
            "lastMessageTimestamp": message.timestamp.timeIntervalSince1970,
            "unreadCount": FieldValue.increment(Int64(1))
        ]
        
        try await db.collection("conversations")
            .document(conversationId)
            .setData(conversationData, merge: true)
        
        // Send push notification
        if let token = receiverToken {
            await sendPushNotification(to: token, title: senderName, body: text, conversationId: conversationId)
        }
    }
    
    // MARK: - Mark Messages as Read
    func markMessagesAsRead(conversationId: String, userId: String) async throws {
        let snapshot = try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        let batch = db.batch()
        for document in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: document.reference)
        }
        try await batch.commit()
        
        // Reset unread count
        try await db.collection("conversations")
            .document(conversationId)
            .updateData(["unreadCount": 0])
    }
    
    // MARK: - Helper Methods
    func getConversationId(userId1: String, userId2: String) -> String {
        return userId1 < userId2 ? "\(userId1)_\(userId2)" : "\(userId2)_\(userId1)"
    }
    
    private func sendPushNotification(to token: String, title: String, body: String, conversationId: String) async {
        // This would typically call your Firebase Cloud Functions endpoint
        // For now, we'll just print a message
        print("Would send push notification to token: \(token)")
        print("Title: \(title), Body: \(body)")
        
        // In production, you would call your Cloud Function here:
        // let url = URL(string: "https://your-cloud-function-url.com/sendNotification")!
        // var request = URLRequest(url: url)
        // request.httpMethod = "POST"
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // let payload = ["token": token, "title": title, "body": body, "conversationId": conversationId]
        // request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        // let (_, _) = try? await URLSession.shared.data(for: request)
    }
    
    func cleanup() {
        messagesListener?.remove()
        conversationsListener?.remove()
        messages.removeAll()
        conversations.removeAll()
        users.removeAll()
    }
}
