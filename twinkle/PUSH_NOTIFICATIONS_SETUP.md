# 🔔 Push Notifications Setup Guide

This guide will help you set up push notifications for the Twinkle chat app so that users receive notifications when they get messages while the app is minimized or closed.

## Prerequisites

- ✅ Firebase project set up
- ✅ iOS app registered in Firebase
- ✅ Xcode project configured with Firebase
- ✅ Physical iOS device (push notifications don't work in Simulator)
- ✅ Apple Developer account with paid membership

---

## Part 1: Apple Push Notification Service (APNs) Setup

### Step 1: Create APNs Authentication Key

1. Go to [Apple Developer Account](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click on **Keys** in the sidebar
4. Click the **+** button to create a new key
5. Give it a name (e.g., "Twinkle Push Notifications")
6. Check **Apple Push Notifications service (APNs)**
7. Click **Continue** → **Register**
8. **Download the .p8 file** (you can only download this once!)
9. Note the **Key ID** (you'll need this)

### Step 2: Get Your Team ID

1. On the Apple Developer Account page
2. Click on **Membership** in the sidebar
3. Note your **Team ID**

### Step 3: Upload APNs Key to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the **gear icon** → **Project settings**
4. Go to the **Cloud Messaging** tab
5. Scroll to **Apple app configuration**
6. Under **APNs Authentication Key**, click **Upload**
7. Upload your **.p8 file**
8. Enter your **Key ID**
9. Enter your **Team ID**
10. Click **Upload**

---

## Part 2: Xcode Project Configuration

### Step 1: Enable Push Notifications Capability

1. Open your project in Xcode
2. Select your **target** (twinkle)
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Push Notifications**

### Step 2: Enable Background Modes

1. Still in **Signing & Capabilities**
2. Click **+ Capability**
3. Add **Background Modes**
4. Check these options:
   - ✅ **Remote notifications**
   - ✅ **Background fetch** (optional)

### Step 3: Verify Bundle Identifier

1. Make sure your Bundle Identifier matches exactly what's in Firebase
2. Should be something like: `com.yourcompany.twinkle`

### Step 4: Add Info.plist Entries (Optional but recommended)

Add these keys to your `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>fetch</string>
</array>
```

---

## Part 3: Deploy Firebase Cloud Functions

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase

```bash
firebase login
```

### Step 3: Initialize Cloud Functions

```bash
# Navigate to your project directory
cd /path/to/your/project

# Initialize Firebase (if not already done)
firebase init functions
```

Choose:
- JavaScript (or TypeScript if you prefer)
- Install dependencies with npm: Yes

### Step 4: Replace functions/index.js

1. Navigate to the `functions` folder in your project
2. Replace the content of `index.js` with the code from `CloudFunctions_index.js`
3. Make sure these dependencies are in `functions/package.json`:

```json
{
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  }
}
```

### Step 5: Install Dependencies

```bash
cd functions
npm install
```

### Step 6: Deploy to Firebase

```bash
# From the functions directory
firebase deploy --only functions

# Or from project root
firebase deploy --only functions
```

You should see output like:
```
✔  functions[sendMessageNotification(us-central1)] Successful create operation.
✔  functions[updateUnreadCount(us-central1)] Successful create operation.
```

---

## Part 4: Firestore Security Rules

Update your Firestore security rules to allow the Cloud Functions to access user data:

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
      allow create: if request.auth != null && 
                       request.auth.uid in request.resource.data.participantIds;
      allow update: if request.auth != null && 
                       request.auth.uid in resource.data.participantIds;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null && 
                       request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
        allow create: if request.auth != null && 
                         request.auth.uid == request.resource.data.senderId;
        allow update: if request.auth != null && 
                         request.auth.uid == resource.data.receiverId;
      }
    }
  }
}
```

Deploy the rules:
```bash
firebase deploy --only firestore:rules
```

---

## Part 5: Testing

### Test on Physical Device

1. **Build and run** the app on a physical iOS device
2. **Sign in** with an account
3. **Check the console** for the FCM token:
   - You should see: `FCM Token: ey...`
4. **Verify token is saved** in Firestore:
   - Go to Firebase Console → Firestore Database
   - Check the `users` collection
   - Your user document should have an `fcmToken` field

### Test Notifications

1. **Use two devices** or one device and Firebase Console
2. **Device A**: Sign in and keep app open
3. **Device B**: Sign in with different account
4. **Device B**: Send a message to Device A's user
5. **Device A**: Minimize or close the app
6. **Device B**: Send another message
7. **Device A**: Should receive a push notification! 🎉

### Debugging

Check Firebase Cloud Functions logs:
```bash
firebase functions:log
```

Look for:
- ✅ "Successfully sent notification"
- ❌ "No FCM token for receiver"
- ❌ "Receiver is online, skipping notification"

---

## Common Issues & Solutions

### ❌ "No FCM token for receiver"

**Problem**: The receiver's device hasn't registered for push notifications.

**Solution**:
1. Make sure the app requests notification permissions
2. Check that `requestAuthorization()` is called in `ConversationListView.onAppear`
3. Verify `registerForRemoteNotifications()` is called
4. Check Xcode console for FCM token

### ❌ "Failed to register for remote notifications"

**Problem**: APNs setup issue.

**Solution**:
1. Verify Push Notifications capability is enabled
2. Make sure you're testing on a physical device
3. Check that APNs key is uploaded to Firebase
4. Verify Bundle ID matches

### ❌ Notifications not appearing when app is in background

**Problem**: Background Modes not enabled or notification permissions denied.

**Solution**:
1. Enable "Remote notifications" in Background Modes
2. Check Settings → Notifications → Twinkle → Allow Notifications is ON
3. Make sure `isOnline` is false when app is backgrounded

### ❌ Cloud Function not triggering

**Problem**: Function deployment failed or permissions issue.

**Solution**:
1. Check deployment: `firebase functions:log`
2. Verify Firestore rules allow reading user data
3. Test function manually in Firebase Console

### ❌ Simulator not receiving notifications

**Problem**: Simulators don't support push notifications.

**Solution**: Always test on a physical device

---

## Testing Checklist

- [ ] APNs key uploaded to Firebase
- [ ] Push Notifications capability enabled
- [ ] Background Modes enabled
- [ ] Cloud Functions deployed successfully
- [ ] Firestore rules updated
- [ ] App runs on physical device
- [ ] FCM token appears in console
- [ ] FCM token saved in Firestore
- [ ] Notification permission granted
- [ ] Send message while app is open (no notification)
- [ ] Minimize app and send message (notification appears! 🎉)
- [ ] Tap notification (opens correct chat)
- [ ] Badge count updates

---

## Architecture Overview

```
┌─────────────────┐
│   Device A      │
│   (Sender)      │
└────────┬────────┘
         │
         │ 1. Send message
         ▼
┌─────────────────────────┐
│   Firestore             │
│   conversations/xxx/    │
│   messages/yyy          │
└────────┬────────────────┘
         │
         │ 2. onCreate trigger
         ▼
┌─────────────────────────┐
│   Cloud Function        │
│   sendMessageNotification│
└────────┬────────────────┘
         │
         │ 3. Get receiver's FCM token
         │ 4. Check if receiver is online
         ▼
┌─────────────────────────┐
│   Firebase Cloud        │
│   Messaging (FCM)       │
└────────┬────────────────┘
         │
         │ 5. Send via APNs
         ▼
┌─────────────────────────┐
│   Apple Push            │
│   Notification Service  │
└────────┬────────────────┘
         │
         │ 6. Deliver notification
         ▼
┌─────────────────┐
│   Device B      │
│   (Receiver)    │
│   🔔 Ding!      │
└─────────────────┘
```

---

## Next Steps

After push notifications are working:

1. **Customize notification sound** - Add custom sounds to your app
2. **Rich notifications** - Add images or actions to notifications
3. **Notification categories** - Add "Reply" action button
4. **Badge management** - Update app badge count
5. **Group notifications** - Group messages from same user
6. **Quiet hours** - Don't send notifications during certain times

---

## Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Apple Push Notifications Guide](https://developer.apple.com/documentation/usernotifications)
- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)

---

**Need Help?** Check the Firebase Console logs and Xcode console for detailed error messages.

Made with ❤️ for Twinkle Chat App
