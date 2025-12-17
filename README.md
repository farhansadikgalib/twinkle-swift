# 💬 Twinkle - iOS Messaging App

A modern, real-time messaging application for iOS built with SwiftUI, Firebase, and Sign in with Apple.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://www.apple.com/ios/)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-yellow.svg)](https://firebase.google.com)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green.svg)](https://developer.apple.com/xcode/swiftui/)

## ✨ Features

- 🍎 **Sign in with Apple** - Secure, privacy-focused authentication
- 💬 **Real-time Messaging** - Instant message delivery with Firebase Firestore
- 👥 **User Presence** - See who's online and when they were last active
- 🔔 **Push Notifications** - Get notified of new messages
- 🔍 **Search** - Find users and conversations easily
- 🎨 **Beautiful UI** - Modern gradient design with smooth animations
- 🔐 **Privacy First** - Support for "Hide My Email" feature
- 📱 **iOS Native** - Built entirely with SwiftUI

## 📱 Screenshots

> Add your app screenshots here

## 🚀 Quick Start

### Prerequisites

- Xcode 15.0+
- iOS 15.0+
- Apple Developer Account
- Firebase Account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/twinkle.git
   cd twinkle
   ```

2. **Add Firebase SDK**
   - In Xcode: File → Add Packages
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Add: `FirebaseAuth`, `FirebaseFirestore`, `FirebaseMessaging`

3. **Configure Firebase**
   - Create a project at [Firebase Console](https://console.firebase.google.com)
   - Download `GoogleService-Info.plist`
   - Add it to your Xcode project (⚠️ Don't commit this file!)

4. **Setup Sign in with Apple**
   - Follow the detailed guide in [`SETUP_CHECKLIST.md`](SETUP_CHECKLIST.md)
   - Enable capability in Xcode
   - Configure Apple Developer Portal
   - Enable Apple provider in Firebase

5. **Build and Run**
   ```bash
   # Open in Xcode
   open twinkle.xcodeproj
   
   # Or use command line
   xcodebuild -scheme twinkle -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
   ```

## 📖 Documentation

- **[Setup Checklist](SETUP_CHECKLIST.md)** - Complete setup guide with checkboxes
- **[Sign in with Apple Setup](SIGN_IN_WITH_APPLE_SETUP.md)** - Detailed Apple Sign In configuration
- **[Firebase Setup](FIREBASE_SETUP.md)** - Firebase SDK installation guide
- **[Build Status](BUILD_STATUS.md)** - Build documentation and requirements
- **[Ready to Run](READY_TO_RUN.md)** - Quick start guide

## 🏗️ Architecture

### Models
- **ChatUser** - User profile data
- **Message** - Chat message data
- **Conversation** - Conversation metadata

### Services
- **AuthenticationService** - Handles Apple Sign In and user authentication
- **ChatService** - Manages real-time messaging and conversations
- **NotificationService** - Handles push notifications
- **UserDefaultsManager** - Local data persistence

### Views
- **SplashScreenView** - App launch screen
- **SignInView** - Apple Sign In interface
- **ConversationListView** - Main conversations list
- **ChatView** - Individual chat interface
- **NewConversationView** - User selection for new chats

## 🔐 Security

- ✅ Secure nonce generation for Apple Sign In
- ✅ SHA256 hashing for authentication
- ✅ Firebase Authentication integration
- ✅ Firestore security rules required
- ✅ No sensitive data stored locally
- ✅ Support for Apple's "Hide My Email"

### Important Security Notes

**Never commit these files:**
- `GoogleService-Info.plist` - Contains Firebase API keys
- `*.p8` files - Apple Sign In private keys
- `*.mobileprovision` - Provisioning profiles
- Any API keys or secrets

## 🛠️ Technologies Used

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Authentication**: Firebase Auth + Sign in with Apple
- **Database**: Firebase Firestore
- **Notifications**: Firebase Cloud Messaging
- **Architecture**: MVVM with Combine
- **Deployment**: iOS 15.0+

## 📦 Dependencies

- [Firebase iOS SDK](https://github.com/firebase/firebase-ios-sdk)
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseMessaging

## 🧪 Testing

```bash
# Run tests in Xcode
⌘U

# Or via command line
xcodebuild test -scheme twinkle -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## 📝 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
      allow write: if request.auth != null;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }
  }
}
```

## 🗺️ Roadmap

- [ ] Group chats
- [ ] Image/video sharing
- [ ] Voice messages
- [ ] Message reactions
- [ ] Dark mode support
- [ ] iPad optimization
- [ ] Message search
- [ ] User blocking
- [ ] Profile customization
- [ ] Message encryption

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Farhan**
- Created: December 17, 2025

## 🙏 Acknowledgments

- [Firebase](https://firebase.google.com) - Backend infrastructure
- [Apple Sign In](https://developer.apple.com/sign-in-with-apple/) - Secure authentication
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Modern UI framework

## 📞 Support

If you have any questions or need help, please:
- Check the [documentation](SETUP_CHECKLIST.md)
- Open an [issue](https://github.com/YOUR_USERNAME/twinkle/issues)
- Read the [troubleshooting guide](BUILD_STATUS.md#troubleshooting)

## ⭐ Show Your Support

If you like this project, please give it a ⭐ on GitHub!

---

**Made with ❤️ and SwiftUI**
