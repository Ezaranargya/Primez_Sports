import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/notification_model.dart';

class NotificationMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔄 Salin notifikasi dari `users/{userId}/notifications` ke koleksi global `notifications`
  Future<void> copyFromUserToGlobal(String userId) async {
    try {
      print('🔄 Starting migration for user: $userId');

      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      print('📦 Found ${notificationsSnapshot.docs.length} notifications');

      int successCount = 0;
      int errorCount = 0;

      for (var doc in notificationsSnapshot.docs) {
        try {
          final data = doc.data();

          // Pastikan field sesuai model terbaru
          final notif = AppNotification.fromFirestore(data, doc.id).copyWith(
            userId: userId, // jaga supaya tetap tahu asal user-nya
            createdAt: data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            isRead: data['isRead'] ?? false,
          );

          await _firestore
              .collection('notifications')
              .doc(doc.id)
              .set(notif.toFirestore(), SetOptions(merge: true));

          successCount++;
          print('✅ Copied: ${doc.id}');
        } catch (e, st) {
          errorCount++;
          print('❌ Error copying ${doc.id}: $e');
          print(st);
        }
      }

      print('═══════════════════════════════════════');
      print('✅ Migration completed for user: $userId');
      print('   Success: $successCount');
      print('   Errors: $errorCount');
      print('═══════════════════════════════════════');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// 🔄 Migrasi semua user
  Future<void> copyAllUsersNotificationsToGlobal() async {
    try {
      print('🔄 Starting migration for ALL users...');

      final usersSnapshot = await _firestore.collection('users').get();
      print('👥 Found ${usersSnapshot.docs.length} users');

      int totalSuccess = 0;
      int totalErrors = 0;

      for (var userDoc in usersSnapshot.docs) {
        print('\n📂 Processing user: ${userDoc.id}');

        final notificationsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .get();

        print('   Found ${notificationsSnapshot.docs.length} notifications');

        for (var notifDoc in notificationsSnapshot.docs) {
          try {
            final data = notifDoc.data();

            final notif = AppNotification.fromFirestore(data, notifDoc.id)
                .copyWith(
              userId: userDoc.id,
              createdAt: data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
              isRead: data['isRead'] ?? false,
            );

            await _firestore
                .collection('notifications')
                .doc(notifDoc.id)
                .set(notif.toFirestore(), SetOptions(merge: true));

            totalSuccess++;
            print('   ✅ Copied: ${notifDoc.id}');
          } catch (e, st) {
            totalErrors++;
            print('   ❌ Error: ${notifDoc.id} - $e');
            print(st);
          }
        }
      }

      print('\n═══════════════════════════════════════');
      print('✅ ALL USERS MIGRATION COMPLETED!');
      print('   Total Success: $totalSuccess');
      print('   Total Errors: $totalErrors');
      print('═══════════════════════════════════════');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// 🧹 Hapus semua notifikasi di `users/{userId}/notifications`
  Future<void> cleanupUserNotifications(String userId) async {
    try {
      print('🗑️ Cleaning up notifications for user: $userId');

      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in notificationsSnapshot.docs) {
        batch.delete(doc.reference);
        count++;

        // Commit batch setiap 500 dokumen agar tidak overload
        if (count % 500 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }

      if (count % 500 != 0) {
        await batch.commit();
      }

      print('✅ Deleted $count notifications from user collection');
    } catch (e) {
      print('❌ Cleanup failed: $e');
      rethrow;
    }
  }
}
