import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        print('⚠️ Retry ${i + 1}/$maxRetries after error: $e');
        await Future.delayed(delay * (i + 1));
      }
    }
    throw Exception('Max retries exceeded');
  }

  Future<void> sendNotificationToAllUsers({
    required String title,
    required String message,
    required String imageUrl,
    required String brand,
    required String type,
    required String productId,
    required List<String> categories,
  }) async {
    try {
      print('📤 Sending notification to all users...');
      print('📤 Title: $title');
      print('📤 Message: $message');
      print('📤 ImageUrl length: ${imageUrl.length}');
      
      final usersSnapshot = await _retryOperation(() => 
        _firestore.collection('users').get().timeout(const Duration(seconds: 30))
      );
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (var userDoc in usersSnapshot.docs) {
        final notifRef = _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();
            
        batch.set(notifRef, {
          'title': title,
          'message': message,
          'imageUrl': imageUrl,
          'brand': brand,
          'type': type,
          'productId': productId,
          'categories': categories,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
        
        count++;
        
        if (count % 500 == 0) {
          await batch.commit();
          print('📦 Committed batch of 500 notifications');
        }
      }
      
      if (count % 500 != 0) {
        await batch.commit();
      }
      
      print('✅ Notifications sent to ${usersSnapshot.docs.length} users');
    } catch (e) {
      print('❌ Error sending notifications: $e');
      rethrow;
    }
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String imageUrl = '',
    String brand = '',
    String type = 'general',
    String productId = '',
    List<String> categories = const [],
  }) async {
    try {
      await _retryOperation(() => 
        _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
          'title': title,
          'message': message,
          'imageUrl': imageUrl,
          'brand': brand,
          'type': type,
          'productId': productId,
          'categories': categories,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 10))
      );

      print('✅ Notification sent to user $userId');
    } catch (e) {
      print('❌ Error sending notification to user: $e');
      rethrow;
    }
  }

  Future<void> sendGlobalNotification({
    required String title,
    required String message,
    required String imageUrl,
    required String brand,
    required String type,
    required String productId,
  }) async {
    try {
      print('📤 Sending global notification...');
      print('📤 Title: $title');
      print('📤 Message: $message');
      print('📤 ImageUrl length: ${imageUrl.length}');
      
      await _retryOperation(() =>
        _firestore.collection('notifications').add({
          'title': title,
          'message': message,
          'imageUrl': imageUrl,
          'brand': brand,
          'type': type,
          'productId': productId,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 10))
      );
      
      print('✅ Global notification sent successfully');
    } catch (e) {
      print('❌ Error sending global notification: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _retryOperation(() =>
        _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true})
            .timeout(const Duration(seconds: 5))
      );
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  Future<void> markGlobalAsRead(String userId, String globalNotifId) async {
    try {
      await _retryOperation(() =>
        _firestore
            .collection('users')
            .doc(userId)
            .collection('readGlobalNotifications')
            .doc(globalNotifId)
            .set({
          'readAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 5))
      );
      print('✅ Global notification marked as read: $globalNotifId');
    } catch (e) {
      print('❌ Error marking global notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final notifications = await _retryOperation(() =>
        _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .get()
            .timeout(const Duration(seconds: 10))
      );

      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await _retryOperation(() => 
        batch.commit().timeout(const Duration(seconds: 15))
      );
      
      print('✅ All notifications marked as read for user $userId');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _retryOperation(() =>
        _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .delete()
            .timeout(const Duration(seconds: 5))
      );
      print('✅ Notification deleted');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  Future<void> deleteGlobalNotification(String notificationId) async {
    try {
      await _retryOperation(() =>
        _firestore
            .collection('notifications')
            .doc(notificationId)
            .delete()
            .timeout(const Duration(seconds: 5))
      );
      print('✅ Global notification deleted');
    } catch (e) {
      print('❌ Error deleting global notification: $e');
    }
  }

  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          print('❌ Error in personal unread count stream: $error');
          return 0;
        });
  }

  Stream<int> getCombinedUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .asyncMap((personalSnapshot) async {
      try {
        final personalCount = personalSnapshot.docs.length;
        
        final globalSnapshot = await _firestore
            .collection('notifications')
            .get()
            .timeout(const Duration(seconds: 5));

        final readGlobalSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('readGlobalNotifications')
            .get()
            .timeout(const Duration(seconds: 3));

        final readGlobalIds = readGlobalSnapshot.docs.map((doc) => doc.id).toSet();
        
        int globalUnreadCount = 0;
        for (var doc in globalSnapshot.docs) {
          if (!readGlobalIds.contains(doc.id)) {
            globalUnreadCount++;
          }
        }

        print('📊 Unread count - Personal: $personalCount, Global: $globalUnreadCount');
        return personalCount + globalUnreadCount;
      } catch (e) {
        print('⚠️ Error getting global unread count: $e');
        return personalSnapshot.docs.length;
      }
    }).handleError((error) {
      print('❌ Error in combined unread count stream: $error');
      return 0;
    });
  }

  Future<void> notifyNewProduct({
    required String productName,
    required String productId,
    required String imageUrl,
    required String brand,
    List<String> categories = const [],
  }) async {
    await sendGlobalNotification(
      title: 'Produk Terbaru!',
      message: '$productName baru saja dirilis!',
      imageUrl: imageUrl,
      brand: brand,
      type: 'product',
      productId: productId,
    );
  }

  Future<void> notifyOrderStatus({
    required String userId,
    required String orderId,
    required String status,
    required String productName,
  }) async {
    String message;
    switch (status.toLowerCase()) {
      case 'processing':
        message = 'Pesanan $productName Anda sedang diproses';
        break;
      case 'shipped':
        message = 'Pesanan $productName Anda sudah dikirim';
        break;
      case 'delivered':
        message = 'Pesanan $productName Anda sudah sampai';
        break;
      case 'cancelled':
        message = 'Pesanan $productName Anda dibatalkan';
        break;
      default:
        message = 'Status pesanan $productName Anda: $status';
    }

    await sendNotificationToUser(
      userId: userId,
      title: 'Update Pesanan',
      message: message,
      type: 'order',
      productId: orderId,
    );
  }

  Future<void> notifyPriceDrop({
    required String productName,
    required String productId,
    required String imageUrl,
    required String brand,
    required String oldPrice,
    required String newPrice,
  }) async {
    await sendGlobalNotification(
      title: 'Harga Turun! 🔥',
      message: '$productName sekarang hanya $newPrice (dari $oldPrice)',
      imageUrl: imageUrl,
      brand: brand,
      type: 'promo',
      productId: productId,
    );
  }

  Future<void> notifyFlashSale({
    required String productName,
    required String productId,
    required String imageUrl,
    required String brand,
    required String discount,
  }) async {
    await sendGlobalNotification(
      title: 'Flash Sale! ⚡',
      message: '$productName diskon $discount% untuk waktu terbatas!',
      imageUrl: imageUrl,
      brand: brand,
      type: 'promo',
      productId: productId,
    );
  }

  Future<void> notifyNewCommunityPost({
    required String postTitle,
    required String postId,
    required String brand,
  }) async {
    await sendGlobalNotification(
      title: 'Post Baru di Komunitas $brand',
      message: postTitle,
      imageUrl: '',
      brand: brand,
      type: 'community',
      productId: postId,
    );
  }

  Future<void> notifyNewNews({
    required String newsTitle,
    required String newsId,
    required String imageUrl,
  }) async {
    await sendGlobalNotification(
      title: 'Berita Terbaru',
      message: newsTitle,
      imageUrl: imageUrl,
      brand: '',
      type: 'news',
      productId: newsId,
    );
  }
}