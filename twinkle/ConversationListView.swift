//
//  ConversationListView.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import SwiftUI

struct ConversationListView: View {
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var chatService = ChatService.shared
    @StateObject private var notificationService = NotificationService.shared
    
    @State private var showNewConversation = false
    @State private var searchText = ""
    @State private var selectedConversation: Conversation?
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return chatService.conversations
        } else {
            return chatService.conversations.filter { conversation in
                conversation.otherUser?.displayName.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if chatService.conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationsList
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    profileButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    newMessageButton
                }
            }
            .searchable(text: $searchText, prompt: "Search conversations")
            .sheet(isPresented: $showNewConversation) {
                NewConversationView()
            }
            .onAppear {
                setupConversations()
            }
            .onChange(of: notificationService.selectedConversationId) { oldValue, newValue in
                if let conversationId = newValue {
                    handleNotificationTap(conversationId: conversationId)
                }
            }
        }
    }
    
    // MARK: - Views
    private var conversationsList: some View {
        List {
            ForEach(filteredConversations) { conversation in
                NavigationLink {
                    if let otherUser = conversation.otherUser {
                        ChatView(conversation: conversation, otherUser: otherUser)
                    }
                } label: {
                    ConversationRow(conversation: conversation)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.secondary)
            
            Text("No Conversations Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to start a new conversation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showNewConversation = true
            } label: {
                Text("Start Chatting")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .padding(.top, 10)
        }
    }
    
    private var profileButton: some View {
        Menu {
            if let user = authService.currentUser {
                Text(user.displayName)
                Text(user.email)
                    .font(.caption)
                
                Divider()
            }
            
            Button(role: .destructive) {
                Task {
                    try? await authService.signOut()
                }
            } label: {
                Label("Sign Out", systemImage: "arrow.right.square")
            }
        } label: {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var newMessageButton: some View {
        Button {
            showNewConversation = true
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    // MARK: - Methods
    private func setupConversations() {
        guard let userId = authService.currentUser?.id else { return }
        chatService.fetchConversations(userId: userId)
        chatService.fetchUsers(excludingUserId: userId)
        
        Task {
            try? await notificationService.requestAuthorization()
        }
    }
    
    private func handleNotificationTap(conversationId: String) {
        if let conversation = chatService.conversations.first(where: { $0.id == conversationId }) {
            selectedConversation = conversation
        }
        notificationService.selectedConversationId = nil
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay {
                        Text(conversation.otherUser?.displayName.prefix(1).uppercased() ?? "?")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                
                // Online indicator
                if conversation.otherUser?.isOnline == true {
                    Circle()
                        .fill(.green)
                        .frame(width: 16, height: 16)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser?.displayName ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(conversation.lastMessageTimestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ConversationListView()
}
