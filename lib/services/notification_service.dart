import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kirim notifikasi ke SEMUA user yang terdaftar
  Future<void> sendNotificationToAllUsers({
    required String title,
    required String message,
    required String imageUrl,
    String brand = '',
    List<String> categories = const [],
  }) async {
    try {
      // Ambil semua user
      final usersSnapshot = await _firestore.collection('users').get();
      
      print('📤 Sending notification to ${usersSnapshot.docs.length} users...');
      
      // Data notifikasi
      final notificationData = {
        'title': title,
        'message': message,
        'imageUrl': imageUrl,
        'brand': brand,
        'categories': categories,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Batch write untuk efisiensi
      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc(); // Auto-generate ID

        batch.set(notificationRef, notificationData);
        count++;

        // Firestore batch limit adalah 500 operasi
        if (count % 500 == 0) {
          await batch.commit();
          batch = _firestore.batch();
          print('✅ Committed batch of 500 notifications');
        }
      }

      // Commit sisa batch
      if (count % 500 != 0) {
        await batch.commit();
      }

      print('✅ Notification sent to $count users successfully!');
    } catch (e) {
      print('❌ Error sending notification: $e');
      rethrow;
    }
  }

  /// Kirim notifikasi ke user tertentu
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

  /// Tandai notifikasi sebagai sudah dibaca
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

  /// Hapus notifikasi
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

  /// Contoh: Kirim notifikasi saat ada berita baru
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
