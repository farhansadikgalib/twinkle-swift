# FCM Token Issue Fix Summary

## Problem
Messages were not triggering push notifications because the FCM token was not being properly fetched or passed when sending messages.

## Root Cause
The `otherUser.fcmToken` in `ChatView` could be:
1. **Nil** - if the token wasn't saved to Firestore
2. **Stale** - if the conversation data was cached and the user updated their token
3. **Not fetched** - if the conversation was fetched before the user's FCM token was registered

## Solution Implemented

### 1. Added `fetchUserFCMToken` Method to `ChatService`
```swift
func fetchUserFCMToken(userId: String) async -> String? {
    do {
        let document = try await db.collection("users").document(userId).getDocument()
        return document.data()?["fcmToken"] as? String
    } catch {
        print("Error fetching FCM token: \(error.localizedDescription)")
        return nil
    }
}
```

### 2. Updated `sendMessage` in `ChatView`
Now fetches the latest FCM token right before sending the message:
```swift
// Fetch the latest FCM token for the receiver before sending
let receiverToken = await chatService.fetchUserFCMToken(userId: otherUser.id)

try await chatService.sendMessage(
    text: text,
    senderId: currentUser.id,
    senderName: currentUser.displayName,
    receiverId: otherUser.id,
    receiverToken: receiverToken
)
```

### 3. Enhanced Conversation Data Storage
Updated `ChatService.sendMessage` to store the receiver's FCM token in the conversation document:
```swift
let conversationData: [String: Any] = [
    "id": conversationId,
    "participantIds": [senderId, receiverId],
    "lastMessage": text,
    "lastMessageTimestamp": message.timestamp.timeIntervalSince1970,
    "unreadCount": FieldValue.increment(Int64(1)),
    "receiverToken": receiverToken ?? "" // Store FCM token for Cloud Functions
]
```

## How It Works Now

1. **User sends a message** → `ChatView.sendMessage()` is called
2. **Fetch latest FCM token** → `chatService.fetchUserFCMToken()` retrieves the receiver's current token from Firestore
3. **Send message with token** → Message is saved to Firestore with the fresh FCM token
4. **Cloud Function triggers** → Firebase Cloud Function detects new message
5. **Notification sent** → Cloud Function uses the FCM token to send push notification to receiver

## Verification Steps

To verify the fix is working:

1. ✅ Check FCM token is saved when user logs in
   - Look for "FCM Token: ..." in console logs
   
2. ✅ Verify token is in Firestore
   - Open Firebase Console → Firestore → users collection
   - Check that each user document has an `fcmToken` field
   
3. ✅ Test sending a message
   - Send a message to another user
   - Check console for "Fetching FCM token for user: [userId]"
   
4. ✅ Verify Cloud Function receives token
   - Check Firebase Functions logs
   - Should see "New message detected" followed by notification sending

5. ✅ Test notification delivery
   - Close or background the receiver's app
   - Send a message
   - Receiver should get a push notification

## Additional Notes

- The FCM token is automatically updated whenever it changes via the `MessagingDelegate` in `NotificationService`
- The Cloud Function already handles invalid tokens by removing them from the user document
- Notifications can optionally be disabled for online users by uncommenting the relevant code in the Cloud Function

## Files Modified

1. **ChatView.swift**
   - Updated `sendMessage()` method to fetch FCM token before sending

2. **ChatService.swift**
   - Added `fetchUserFCMToken()` method
   - Updated conversation data to include receiver's FCM token

## Testing Checklist

- [ ] User receives notification when app is backgrounded
- [ ] User receives notification when app is closed
- [ ] Notification shows sender's name and message preview
- [ ] Tapping notification opens the correct conversation
- [ ] No notification sent if receiver is actively viewing the conversation
- [ ] Token is properly updated if user logs out and back in
