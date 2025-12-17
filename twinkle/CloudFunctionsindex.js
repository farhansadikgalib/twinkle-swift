// Firebase Cloud Function for Twinkle Chat App
// Deploy this to Firebase Functions to enable push notifications

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Sends a push notification when a new message is created
 * Triggered automatically by Firestore
 */
exports.sendMessageNotification = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const conversationId = context.params.conversationId;
    
    console.log('New message detected:', message.text);
    
    try {
      // Get receiver's user document to fetch FCM token
      const receiverDoc = await admin.firestore()
        .collection('users')
        .doc(message.receiverId)
        .get();
      
      if (!receiverDoc.exists) {
        console.log('Receiver user not found');
        return null;
      }
      
      const receiverData = receiverDoc.data();
      const fcmToken = receiverData.fcmToken;
      
      if (!fcmToken) {
        console.log('Receiver has no FCM token');
        return null;
      }
      
      // Check if receiver is online (optional: don't send notification if online)
      // Uncomment the following if you want to skip notifications for online users
      // if (receiverData.isOnline) {
      //   console.log('Receiver is online, skipping notification');
      //   return null;
      // }
      
      // Construct the notification payload
      const payload = {
        notification: {
          title: message.senderName,
          body: message.text,
          sound: 'default',
          badge: '1'
        },
        data: {
          conversationId: conversationId,
          senderId: message.senderId,
          senderName: message.senderName,
          type: 'message',
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              'content-available': 1
            }
          }
        }
      };
      
      // Send the notification
      const response = await admin.messaging().sendToDevice(fcmToken, payload);
      
      // Log the result
      console.log('Successfully sent notification:', response);
      
      // Check for errors
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.results.forEach((result, index) => {
          if (!result.success) {
            failedTokens.push(fcmToken);
            console.error('Failed to send to token:', result.error);
            
            // If token is invalid, remove it from user document
            if (result.error.code === 'messaging/invalid-registration-token' ||
                result.error.code === 'messaging/registration-token-not-registered') {
              admin.firestore()
                .collection('users')
                .doc(message.receiverId)
                .update({ fcmToken: admin.firestore.FieldValue.delete() });
            }
          }
        });
      }
      
      return response;
      
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });

/**
 * Updates unread message count for a user
 * Optional: Use this to maintain accurate badge counts
 */
exports.updateUnreadCount = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const conversationId = context.params.conversationId;
    
    try {
      // Increment unread count for receiver
      await admin.firestore()
        .collection('conversations')
        .doc(conversationId)
        .update({
          unreadCount: admin.firestore.FieldValue.increment(1)
        });
      
      console.log('Unread count updated');
      return null;
      
    } catch (error) {
      console.error('Error updating unread count:', error);
      return null;
    }
  });

/**
 * Clean up old messages (optional)
 * Runs daily to delete messages older than 30 days
 */
exports.cleanupOldMessages = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const db = admin.firestore();
    const thirtyDaysAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);
    
    try {
      const conversationsSnapshot = await db.collection('conversations').get();
      
      for (const conversationDoc of conversationsSnapshot.docs) {
        const messagesSnapshot = await conversationDoc.ref
          .collection('messages')
          .where('timestamp', '<', thirtyDaysAgo)
          .get();
        
        const batch = db.batch();
        messagesSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        
        await batch.commit();
        console.log(`Deleted ${messagesSnapshot.size} old messages from ${conversationDoc.id}`);
      }
      
      return null;
    } catch (error) {
      console.error('Error cleaning up old messages:', error);
      return null;
    }
  });

/**
 * Update user's last seen when they go offline
 * Triggered when user's isOnline status changes
 */
exports.updateLastSeen = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Check if user went offline
    if (before.isOnline && !after.isOnline) {
      try {
        await change.after.ref.update({
          lastSeen: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('Updated last seen for user:', context.params.userId);
      } catch (error) {
        console.error('Error updating last seen:', error);
      }
    }
    
    return null;
  });

/* 
 * DEPLOYMENT INSTRUCTIONS:
 * 
 * 1. Install Firebase CLI:
 *    npm install -g firebase-tools
 * 
 * 2. Initialize Firebase Functions (if not already done):
 *    firebase init functions
 * 
 * 3. Navigate to functions directory:
 *    cd functions
 * 
 * 4. Install dependencies:
 *    npm install
 * 
 * 5. Copy this file to functions/index.js
 * 
 * 6. Deploy to Firebase:
 *    firebase deploy --only functions
 * 
 * 7. Monitor logs:
 *    firebase functions:log
 * 
 * Note: Make sure your Firebase project is selected:
 *    firebase use <your-project-id>
 */
