# 🌟 Twinkle - Modern iOS Chat Application

A beautifully designed, real-time chat application for iOS built with SwiftUI, Firebase, and following the MVC architectural pattern. Inspired by Apple's Messages app with modern UI/UX principles.

## ✨ Features

### Core Functionality
- 🔐 **Authentication**: Email/Password sign-in and sign-up with Firebase Auth
- 💾 **Persistent Login**: UserDefaults integration to maintain login sessions
- 💬 **Real-time Messaging**: Instant message delivery with Firebase Firestore
- 🔔 **Push Notifications**: Real-time notifications using Firebase Cloud Messaging
- 👥 **User Discovery**: Browse and chat with other users
- 📱 **Notification Deep Linking**: Tap notifications to open specific conversations

### User Interface
- 🎨 **Modern Design**: Beautiful gradient-based UI inspired by Apple Messages
- 🌊 **Splash Screen**: Animated welcome screen with smooth transitions
- 💬 **Message Bubbles**: Apple-style message bubbles with timestamps
- ✅ **Read Receipts**: Visual indicators for message delivery and read status
- 🟢 **Online Status**: Real-time online/offline indicators
- 🔍 **Search**: Search conversations and users
- 🔴 **Unread Badges**: Unread message count indicators
- ⏰ **Relative Timestamps**: Smart time displays (e.g., "5m ago", "2h ago")

### Technical Features
- 🏗️ **MVC Architecture**: Clean separation of concerns
- 🔄 **Real-time Sync**: Firebase Firestore real-time listeners
- 🔒 **Secure**: Firebase security rules implementation
- ⚡ **Async/Await**: Modern Swift concurrency throughout
- 📦 **Modular Design**: Well-organized code structure
- 🎯 **Type Safety**: Strongly typed models and services

## 📱 Screenshots

[Add screenshots here after running the app]

## 🏗️ Architecture

The app follows the **Model-View-Controller (MVC)** pattern:

```
Models/                 # Data structures
├── User.swift         # User model
├── Message.swift      # Message model
└── Conversation.swift # Conversation model

Services/              # Business logic (Controllers)
├── AuthenticationService.swift    # Authentication logic
├── ChatService.swift             # Chat operations
├── NotificationService.swift     # Push notification handling
└── UserDefaultsManager.swift     # Persistent storage

Views/                 # UI components
├── SplashScreenView.swift        # Launch screen
├── SignInView.swift              # Authentication UI
├── ConversationListView.swift    # Chat list
├── NewConversationView.swift     # User selection
└── ChatView.swift                # Message interface
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Firebase account
- Physical iOS device (for testing push notifications)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd twinkle
   ```

2. **Set up Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add an iOS app with bundle ID: `com.yourcompany.twinkle`
   - Download `GoogleService-Info.plist`
   - Drag it into your Xcode project

3. **Install Firebase SDK**
   - In Xcode: File → Add Package Dependencies
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Add: `FirebaseAuth`, `FirebaseFirestore`, `FirebaseMessaging`

4. **Configure Capabilities**
   - Select your target in Xcode
   - Go to "Signing & Capabilities"
   - Add "Push Notifications"
   - Add "Background Modes" → Enable "Remote notifications"

5. **Set up Firebase Services**
   - Enable **Email/Password** authentication
   - Create **Firestore Database** in test mode
   - Upload **APNs key** to Firebase Cloud Messaging
   - Deploy **Cloud Functions** for push notifications

See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) for detailed setup guide.

## 📝 Usage

### Sign Up / Sign In
1. Launch the app
2. Create a new account or sign in with existing credentials
3. Your session will be saved for automatic login

### Start a Conversation
1. Tap the "+" button in the top right
2. Select a user from the list
3. Start chatting!

### Receive Notifications
1. When you receive a message, you'll get a push notification
2. Tap the notification to open the conversation directly
3. Messages are marked as read automatically

## 🔧 Configuration Files

### Firebase Cloud Function

Deploy this function to send push notifications:

```javascript
// See SETUP_INSTRUCTIONS.md for complete Cloud Function code
exports.sendMessageNotification = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    // Send push notification to receiver
  });
```

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    // See SETUP_INSTRUCTIONS.md for complete rules
  }
}
```

## 🎨 Design Principles

- **Apple Human Interface Guidelines**: Following iOS design standards
- **Consistency**: Uniform design language throughout the app
- **Accessibility**: Clear typography and color contrast
- **Feedback**: Visual feedback for all user actions
- **Performance**: Optimized for smooth scrolling and animations

## 🔐 Security

- ✅ Firebase Authentication for secure user management
- ✅ Firestore security rules to protect user data
- ✅ Token-based push notifications
- ✅ Password validation on sign-up
- ✅ Secure data transmission over HTTPS

## 🧪 Testing

### Manual Testing Checklist
- [ ] Sign up with new account
- [ ] Sign in with existing account
- [ ] Send and receive messages
- [ ] Check online/offline status
- [ ] Test push notifications (on physical device)
- [ ] Verify notification tap opens correct chat
- [ ] Test search functionality
- [ ] Verify unread counts
- [ ] Check read receipts
- [ ] Test app restart (login persistence)

## 🚦 Roadmap

Future enhancements:
- [ ] Image and video sharing
- [ ] Group chat support
- [ ] Voice messages
- [ ] Message reactions (emoji)
- [ ] Typing indicators
- [ ] Message search
- [ ] User profile editing
- [ ] Dark mode support
- [ ] Message deletion
- [ ] Block user functionality

## 📚 Dependencies

- **Firebase/Auth**: User authentication
- **Firebase/Firestore**: Real-time database
- **Firebase/Messaging**: Push notifications
- **SwiftUI**: UI framework
- **Swift Concurrency**: Async/await support

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is available for personal and educational use.

## 👨‍💻 Author

Created by Farhan on December 17, 2025

## 🙏 Acknowledgments

- Apple's Messages app for design inspiration
- Firebase for backend infrastructure
- SwiftUI for modern UI development

## 📞 Support

For issues, questions, or suggestions, please open an issue in the repository.

---

Made with ❤️ using SwiftUI and Firebase
