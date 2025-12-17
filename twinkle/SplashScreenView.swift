//
//  SplashScreenView.swift
//  twinkle
//
//  Created by farhan on 17/12/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var isActive = false
    
    @StateObject private var authService = AuthenticationService.shared
    
    var body: some View {
        if isActive {
            if authService.isAuthenticated {
                ConversationListView()
            } else {
                SignInView()
            }
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(.white)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    Text("Twinkle")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(opacity)
                    
                    Text("Connect with friends")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .opacity(opacity)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    scale = 1.0
                    opacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
