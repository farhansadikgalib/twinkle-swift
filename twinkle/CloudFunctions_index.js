/**
 * Firebase Cloud Functions for Twinkle Chat App
 * 
 * Deploy this file to Firebase Cloud Functions to enable push notifications
 * 
 * Setup:
 * 1. cd into your Firebase project directory
 * 2. firebase init functions (select JavaScript)
 * 3. Replace functions/index.js with this file
 * 4. npm install firebase-admin firebase-functions
 * 5. firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Send push notification when a new message is created
 * 
 * Triggers: When a document is created in conversations/{conversationId}/messages/{messageId}
 */
exports.sendMessageNotification = functions.firestore
    .document('conversations/{conversationId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
        try {
            const message = snap.data();
            const conversationId = context.params.conversationId;
            
            // Get receiver's FCM token
            const receiverDoc = await admin.firestore()
                .collection('users')
                .doc(message.receiverId)
                .get();
            
            if (!receiverDoc.exists) {
                console.log('Receiver not found');
                return null;
            }
            
            const receiverData = receiverDoc.data();
            const fcmToken = receiverData.fcmToken;
            
            if (!fcmToken) {
                console.log('No FCM token for receiver');
                return null;
            }
            
            // Check if receiver is online (don't send notification if they are)
            if (receiverData.isOnline) {
                console.log('Receiver is online, skipping notification');
                return null;
            }
            
            // Create notification payload
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
                    messageId: message.id,
                    type: 'new_message'
                },
                apns: {
                    payload: {
                        aps: {
                            alert: {
                                title: message.senderName,
                                body: message.text
                            },
                            sound: 'default',
                            badge: 1,
                            category: 'MESSAGE_CATEGORY',
                            'mutable-content': 1,
                            'content-available': 1
                        }
                    },
                    headers: {
                        'apns-priority': '10',
                        'apns-push-type': 'alert'
                    }
                }
            };
            
            // Send notification
            const response = await admin.messaging().sendToDevice(fcmToken, payload, {
                priority: 'high',
                timeToLive: 60 * 60 * 24 // 24 hours
            });
            
            console.log('Successfully sent notification:', response);
            
            // Check if token is invalid and remove it
            if (response.results[0].error) {
                console.error('Error sending notification:', response.results[0].error);
                
                if (response.results[0].error.code === 'messaging/invalid-registration-token' ||
                    response.results[0].error.code === 'messaging/registration-token-not-registered') {
                    // Remove invalid token
                    await admin.firestore()
                        .collection('users')
                        .doc(message.receiverId)
                        .update({
                            fcmToken: admin.firestore.FieldValue.delete()
                        });
                }
            }
            
            return response;
        } catch (error) {
            console.error('Error sending notification:', error);
            return null;
        }
    });

/**
 * Update unread count when a message is marked as read
 */
exports.updateUnreadCount = functions.firestore
    .document('conversations/{conversationId}/messages/{messageId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        
        // Check if message was just marked as read
        if (!before.isRead && after.isRead) {
            const conversationId = context.params.conversationId;
            
            // Get all unread messages in conversation
            const unreadSnapshot = await admin.firestore()
                .collection('conversations')
                .doc(conversationId)
                .collection('messages')
                .where('receiverId', '==', after.receiverId)
                .where('isRead', '==', false)
                .get();
            
            // Update unread count
            await admin.firestore()
                .collection('conversations')
                .doc(conversationId)
                .update({
                    unreadCount: unreadSnapshot.size
                });
        }
        
        return null;
    });

/**
 * Clean up messages older than 30 days (optional)
 */
exports.cleanupOldMessages = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        const thirtyDaysAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);
        
        const snapshot = await admin.firestore()
            .collectionGroup('messages')
            .where('timestamp', '<', thirtyDaysAgo)
            .get();
        
        const batch = admin.firestore().batch();
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        await batch.commit();
        console.log(`Deleted ${snapshot.size} old messages`);
        
        return null;
    });
