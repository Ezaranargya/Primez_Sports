import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserPhotoUpdater {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update semua post dengan foto profil user yang terbaru
  Future<void> updateAllPostsWithUserPhotos() async {
    try {
      debugPrint('🔄 Starting photo update for all posts...');
      
      // 1. Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      debugPrint('👥 Found ${usersSnapshot.docs.length} users');

      int totalUpdated = 0;
      int totalSkipped = 0;

      // 2. For each user, update their posts
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        final photoUrl = userData['photoUrl'] as String? ?? '';

        debugPrint('📝 Processing user: $userId (${userData['username'] ?? 'Unknown'})');
        debugPrint('   Photo URL: ${photoUrl.isEmpty ? 'EMPTY' : 'EXISTS (${photoUrl.length} chars)'}');

        // Get all posts by this user
        final postsSnapshot = await _firestore
            .collection('community_posts')
            .where('userId', isEqualTo: userId)
            .get();

        debugPrint('   Found ${postsSnapshot.docs.length} posts');

        // Update each post
        for (var postDoc in postsSnapshot.docs) {
          try {
            await postDoc.reference.update({
              'userPhotoUrl': photoUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            totalUpdated++;
            debugPrint('   ✅ Updated post: ${postDoc.id}');
          } catch (e) {
            totalSkipped++;
            debugPrint('   ❌ Failed to update post ${postDoc.id}: $e');
          }
        }
      }

      debugPrint('');
      debugPrint('✅ Photo update completed!');
      debugPrint('   Total posts updated: $totalUpdated');
      debugPrint('   Total posts skipped: $totalSkipped');
    } catch (e) {
      debugPrint('❌ Error in updateAllPostsWithUserPhotos: $e');
      rethrow;
    }
  }

  /// Update posts untuk user tertentu saja
  Future<void> updatePostsForUser(String userId) async {
    try {
      debugPrint('🔄 Updating posts for user: $userId');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found: $userId');
      }

      final photoUrl = userDoc.data()?['photoUrl'] as String? ?? '';
      debugPrint('   Photo URL: ${photoUrl.isEmpty ? 'EMPTY' : 'EXISTS'}');

      // Get all posts by this user
      final postsSnapshot = await _firestore
          .collection('community_posts')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('   Found ${postsSnapshot.docs.length} posts');

      int updated = 0;
      for (var postDoc in postsSnapshot.docs) {
        await postDoc.reference.update({
          'userPhotoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        updated++;
      }

      debugPrint('✅ Updated $updated posts for user $userId');
    } catch (e) {
      debugPrint('❌ Error updating posts for user: $e');
      rethrow;
    }
  }

  /// Check berapa banyak post yang photoUrl-nya kosong
  Future<Map<String, int>> checkMissingPhotos() async {
    try {
      final postsSnapshot = await _firestore
          .collection('community_posts')
          .get();

      int totalPosts = postsSnapshot.docs.length;
      int missingPhotos = 0;
      int hasPhotos = 0;

      for (var doc in postsSnapshot.docs) {
        final photoUrl = doc.data()['userPhotoUrl'] as String? ?? '';
        if (photoUrl.isEmpty) {
          missingPhotos++;
        } else {
          hasPhotos++;
        }
      }

      return {
        'total': totalPosts,
        'missing': missingPhotos,
        'hasPhotos': hasPhotos,
      };
    } catch (e) {
      debugPrint('❌ Error checking missing photos: $e');
      rethrow;
    }
  }
}