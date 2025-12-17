//
//  NewConversationView.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import SwiftUI

struct NewConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatService = ChatService.shared
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var searchText = ""
    @State private var selectedUser: User?
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return chatService.users
        } else {
            return chatService.users.filter { user in
                user.displayName.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredUsers) { user in
                Button {
                    selectedUser = user
                    dismiss()
                } label: {
                    UserRow(user: user)
                }
            }
            .listStyle(.plain)
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search people")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedUser) { oldValue, newValue in
            if let user = newValue {
                navigateToChat(with: user)
            }
        }
    }
    
    private func navigateToChat(with user: User) {
        // This will be handled by the parent view
        // For now, just dismiss
    }
}

// MARK: - User Row
struct UserRow: View {
    let user: User
    
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
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(user.displayName.prefix(1).uppercased())
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                
                // Online indicator
                if user.isOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 14, height: 14)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if user.isOnline {
                    Text("Online")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("Last seen \(user.lastSeen, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NewConversationView()
}
