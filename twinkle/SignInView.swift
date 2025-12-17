//
//  SignInView.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import SwiftUI

struct SignInView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Logo and Title
                        VStack(spacing: 15) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.top, 60)
                            
                            Text("Twinkle")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text(isSignUp ? "Create your account" : "Welcome back")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 30)
                        
                        // Input fields
                        VStack(spacing: 18) {
                            if isSignUp {
                                CustomTextField(
                                    icon: "person.fill",
                                    placeholder: "Display Name",
                                    text: $displayName
                                )
                            }
                            
                            CustomTextField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $email,
                                keyboardType: .emailAddress
                            )
                            
                            CustomTextField(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $password,
                                isSecure: true
                            )
                        }
                        .padding(.horizontal, 30)
                        
                        // Sign In/Up Button
                        Button {
                            Task {
                                await handleAuthentication()
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Sign Up" : "Sign In")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        
                        // Toggle between sign in and sign up
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                isSignUp.toggle()
                                errorMessage = ""
                                showError = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundStyle(.secondary)
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 5)
                        
                        Spacer()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAuthentication() async {
        isLoading = true
        errorMessage = ""
        
        do {
            if isSignUp {
                guard !displayName.isEmpty else {
                    errorMessage = "Please enter your display name"
                    showError = true
                    isLoading = false
                    return
                }
                try await authService.signUp(email: email, password: password, displayName: displayName)
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    SignInView()
}
