import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/models/community_post_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<int> getUnreadPostsCount() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      final lastVisit = userDoc.data()?['lastCommunityVisit'] as Timestamp?;
      
      if (lastVisit == null) {
        final postsSnapshot = await _firestore.collection('posts').get();
        return postsSnapshot.docs.length;
      }

      final newPostsSnapshot = await _firestore
          .collection('posts')
          .where('createdAt', isGreaterThan: lastVisit)
          .get();

      return newPostsSnapshot.docs.length;
    });
  }

  Future<void> markCommunityAsVisited() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).set({
      'lastCommunityVisit': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<CommunityPost>> getAllPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<CommunityPost?> getPostById(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    return CommunityPost.fromMap(doc.data()!, doc.id);
  }

  Future<void> createAdminPost({
    required String brand,
    required String content,
    required String description,
    required String? imageUrl1,
    required List<PostLink> links,
  }) async {
    await _firestore.collection('posts').add({
      'brand': brand,
      'content': content,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl1': imageUrl1,
      'links': links.map((link) => link.toMap()).toList(),
    });

    debugPrint('✅ Admin post created for brand: $brand');
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
    debugPrint('✅ Post deleted: $postId');
  }

  /// Mark all current posts of a brand as read
  Future<void> markBrandPostsAsRead(String brand) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      debugPrint('📝 Marking $brand as read...');

      // Simply store the current server timestamp when user reads
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('read_brands')
          .doc(brand)
          .set({
        'brand': brand,
        'lastReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Successfully marked $brand as read');
    } catch (e) {
      debugPrint('❌ Error marking brand posts as read: $e');
    }
  }

  /// Check if there are unread posts for this brand
  /// Returns true if ALL posts are read, false if there are unread posts
  Stream<bool> isBrandRead(String brand) {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ No user logged in for isBrandRead');
      return Stream.value(false);
    }

    debugPrint('👀 Checking read status for $brand');

    // Combine both streams for real-time updates
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('read_brands')
        .doc(brand)
        .snapshots()
        .asyncMap((readDoc) async {
      
      debugPrint('📊 Read doc exists for $brand: ${readDoc.exists}');

      // Get all posts for this brand
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('brand', isEqualTo: brand)
          .get();

      final totalPosts = postsSnapshot.docs.length;
      debugPrint('📦 Total posts for $brand: $totalPosts');

      // If no posts, consider it as "read" (no badge needed)
      if (totalPosts == 0) {
        debugPrint('✅ No posts for $brand, returning true (no badge)');
        return true;
      }

      // If never marked as read, show badge
      if (!readDoc.exists) {
        debugPrint('🔴 $brand never read, returning false (show badge)');
        return false;
      }

      // Get the last read timestamp - handle both Timestamp and serverTimestamp
      final readData = readDoc.data();
      if (readData == null) {
        debugPrint('🔴 No data in read doc for $brand, returning false (show badge)');
        return false;
      }

      final lastReadAt = readData['lastReadAt'];
      
      // Handle null or pending serverTimestamp
      if (lastReadAt == null) {
        // If lastReadAt is null but doc exists, it means write just happened
        // Consider it as read (optimistic)
        debugPrint('⚠️ lastReadAt is null (pending write), assuming read = true');
        return true;
      }

      final lastReadTimestamp = lastReadAt as Timestamp;
      debugPrint('⏰ Last read at for $brand: $lastReadTimestamp');

      // Check if there are any posts created AFTER the last read time
      final unreadPosts = postsSnapshot.docs.where((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        
        if (createdAt == null) return false;
        
        final isUnread = createdAt.millisecondsSinceEpoch > lastReadTimestamp.millisecondsSinceEpoch;
        if (isUnread) {
          debugPrint('🆕 Found unread post in $brand: ${doc.id} (${createdAt.toDate()} > ${lastReadTimestamp.toDate()})');
        }
        return isUnread;
      }).toList();

      final hasUnread = unreadPosts.isNotEmpty;
      debugPrint('📊 $brand - unread: ${unreadPosts.length}, returning isRead=${!hasUnread}');
      
      // Return true if NO unread posts (hide badge)
      // Return false if HAS unread posts (show badge)
      return !hasUnread;
    });
  }

  /// Get unread count for a specific brand
  Stream<int> getUnreadCountForBrand(String brand) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('read_brands')
        .doc(brand)
        .snapshots()
        .asyncMap((readDoc) async {
      
      // Get all posts for this brand
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('brand', isEqualTo: brand)
          .get();

      final totalPosts = postsSnapshot.docs.length;

      // If no posts, return 0
      if (totalPosts == 0) return 0;

      // If never read, all posts are unread
      if (!readDoc.exists) return totalPosts;

      final lastReadAt = readDoc.data()?['lastReadAt'] as Timestamp?;
      if (lastReadAt == null) return totalPosts;

      // Count posts created after last read time
      final unreadCount = postsSnapshot.docs.where((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        
        if (createdAt == null) return false;
        return createdAt.millisecondsSinceEpoch > lastReadAt.millisecondsSinceEpoch;
      }).length;

      return unreadCount;
    });
  }

  Stream<Map<String, int>> getUnreadCountsByBrand() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({});

    // Listen to posts changes
    return _firestore
        .collection('posts')
        .snapshots()
        .asyncMap((postsSnapshot) async {
      final Map<String, int> counts = {};
      
      // Group posts by brand
      final Map<String, List<QueryDocumentSnapshot>> postsByBrand = {};
      for (var doc in postsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final brand = data?['brand'] as String?;
        if (brand != null) {
          postsByBrand.putIfAbsent(brand, () => []).add(doc);
        }
      }

      // For each brand, calculate unread count
      for (var brand in postsByBrand.keys) {
        final readDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('read_brands')
            .doc(brand)
            .get();

        if (!readDoc.exists) {
          // Never read, all posts are unread
          counts[brand] = postsByBrand[brand]!.length;
        } else {
          final lastReadAt = readDoc.data()?['lastReadAt'] as Timestamp?;

          if (lastReadAt == null) {
            counts[brand] = postsByBrand[brand]!.length;
          } else {
            // Count posts after last read time
            final unreadCount = postsByBrand[brand]!.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              final createdAt = data?['createdAt'] as Timestamp?;
              
              if (createdAt == null) return false;
              return createdAt.millisecondsSinceEpoch > lastReadAt.millisecondsSinceEpoch;
            }).length;
            
            counts[brand] = unreadCount;
          }
        }
      }

      return counts;
    });
  }
}