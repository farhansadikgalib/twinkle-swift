//
//  ChatView.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    let otherUser: User
    
    @StateObject private var chatService = ChatService.shared
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatService.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == authService.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom()
                }
                .onChange(of: chatService.messages.count) { oldValue, newValue in
                    scrollToBottom()
                }
            }
            
            // Input Bar
            inputBar
        }
        .navigationTitle(otherUser.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(otherUser.displayName)
                        .font(.headline)
                    
                    if otherUser.isOnline {
                        Text("Online")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else {
                        Text("Last seen \(otherUser.lastSeen, style: .relative)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            setupChat()
        }
        .onDisappear {
            markAsRead()
        }
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            // Text field
            HStack(spacing: 8) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Send button
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                        LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Methods
    private func setupChat() {
        chatService.fetchMessages(conversationId: conversation.id)
        
        // Mark messages as read after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            markAsRead()
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty,
              let currentUser = authService.currentUser else { return }
        
        Task {
            do {
                try await chatService.sendMessage(
                    text: text,
                    senderId: currentUser.id,
                    senderName: currentUser.displayName,
                    receiverId: otherUser.id,
                    receiverToken: otherUser.fcmToken
                )
                
                await MainActor.run {
                    messageText = ""
                    scrollToBottom()
                }
            } catch {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    private func scrollToBottom() {
        guard let lastMessage = chatService.messages.last else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func markAsRead() {
        guard let userId = authService.currentUser?.id else { return }
        
        Task {
            try? await chatService.markMessagesAsRead(conversationId: conversation.id, userId: userId)
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        isFromCurrentUser ?
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: isFromCurrentUser ? 18 : 4,
                            bottomTrailingRadius: isFromCurrentUser ? 4 : 18,
                            topTrailingRadius: 18
                        )
                    )
                
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if isFromCurrentUser {
                        Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.caption2)
                            .foregroundStyle(message.isRead ? .blue : .secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(
            conversation: Conversation(
                id: "test",
                participantIds: ["user1", "user2"],
                lastMessage: "Hello!",
                lastMessageTimestamp: Date()
            ),
            otherUser: User(
                id: "user2",
                email: "test@example.com",
                displayName: "John Doe",
                isOnline: true
            )
        )
    }
}
