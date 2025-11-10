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

    print('✅ Admin post created for brand: $brand');
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
    print('✅ Post deleted: $postId');
  }

  Future<void> markBrandPostsAsRead(String brand) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('read_posts')
          .doc(brand)
          .set({
        'brand': brand,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking brand posts as read: $e');
    }
  }

  Stream<bool> isBrandRead(String brand) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('read_posts')
        .doc(brand)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<Map<String, int>> getUnreadCountsByBrand() {
    return getAllPosts().map((posts) {
      final Map<String, int> counts = {};
      for (var post in posts) {
        counts[post.brand] = (counts[post.brand] ?? 0) + 1;
      }
      return counts;
    });
  }
}