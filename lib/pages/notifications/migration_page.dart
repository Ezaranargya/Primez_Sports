import 'package:cloud_firestore/cloud_firestore.dart';

/// Script untuk copy notifikasi dari users/{userId}/notifications ke notifications/
/// 
/// Cara pakai:
/// 1. Panggil function ini dari button di admin page atau main.dart
/// 2. Atau buat page khusus untuk migration
class NotificationMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Copy notifikasi dari user tertentu ke collection global
  Future<void> copyFromUserToGlobal(String userId) async {
    try {
      print('🔄 Starting migration for user: $userId');
      
      // Ambil semua notifikasi dari user
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
          
          // Copy ke collection global dengan ID yang sama
          await _firestore
              .collection('notifications')
              .doc(doc.id)
              .set(data);
          
          successCount++;
          print('✅ Copied: ${doc.id}');
        } catch (e) {
          errorCount++;
          print('❌ Error copying ${doc.id}: $e');
        }
      }

      print('═══════════════════════════════════════');
      print('✅ Migration completed!');
      print('   Success: $successCount');
      print('   Errors: $errorCount');
      print('═══════════════════════════════════════');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Copy semua notifikasi dari semua user ke collection global
  Future<void> copyAllUsersNotificationsToGlobal() async {
    try {
      print('🔄 Starting migration for ALL users...');
      
      // Ambil semua user
      final usersSnapshot = await _firestore.collection('users').get();
      
      print('👥 Found ${usersSnapshot.docs.length} users');

      int totalSuccess = 0;
      int totalErrors = 0;

      for (var userDoc in usersSnapshot.docs) {
        print('\n📂 Processing user: ${userDoc.id}');
        
        // Ambil notifikasi user ini
        final notificationsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .get();

        print('   Found ${notificationsSnapshot.docs.length} notifications');

        for (var notifDoc in notificationsSnapshot.docs) {
          try {
            final data = notifDoc.data();
            
            // Copy ke global collection
            await _firestore
                .collection('notifications')
                .doc(notifDoc.id)
                .set(data, SetOptions(merge: true)); // merge untuk avoid overwrite
            
            totalSuccess++;
            print('   ✅ Copied: ${notifDoc.id}');
          } catch (e) {
            totalErrors++;
            print('   ❌ Error: ${notifDoc.id} - $e');
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

  /// Hapus notifikasi dari user setelah berhasil di-copy
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
        
        // Batch limit 500
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