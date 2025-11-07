import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<void> sendNotificationToAllUsers({
    required String title,
    required String message,
    required String imageUrl,
    String brand = '',
    List<String> categories = const [],
  }) async {
    try {
      
      final usersSnapshot = await _firestore.collection('users').get();
      
      print('📤 Sending notification to ${usersSnapshot.docs.length} users...');
      
      
      final notificationData = {
        'title': title,
        'message': message,
        'imageUrl': imageUrl,
        'brand': brand,
        'categories': categories,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      
      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc(); 

        batch.set(notificationRef, notificationData);
        count++;

        
        if (count % 500 == 0) {
          await batch.commit();
          batch = _firestore.batch();
          print('✅ Committed batch of 500 notifications');
        }
      }

      
      if (count % 500 != 0) {
        await batch.commit();
      }

      print('✅ Notification sent to $count users successfully!');
    } catch (e) {
      print('❌ Error sending notification: $e');
      rethrow;
    }
  }

  
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required String imageUrl,
    String brand = '',
    List<String> categories = const [],
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'imageUrl': imageUrl,
        'brand': brand,
        'categories': categories,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification sent to user $userId');
    } catch (e) {
      print('❌ Error sending notification to user: $e');
      rethrow;
    }
  }

  
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  
  Future<void> notifyNewProduct(String productName, String imageUrl) async {
    await sendNotificationToAllUsers(
      title: 'Produk Terbaru!',
      message: '$productName baru saja dirilis!',
      imageUrl: imageUrl,
      brand: 'Puma',
      categories: ['terbaru', 'produk'],
    );
  }
}
