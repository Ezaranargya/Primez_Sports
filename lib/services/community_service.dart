import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/models/comment_model.dart';
import 'package:my_app/services/supabase_storage_service.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final SupabaseStorageService _storage = SupabaseStorageService();
  
  // ✅ IMPROVED: Better user info retrieval with consistent field names
  Future<Map<String, String>> getCurrentUserInfo() async {
    final user = _auth.currentUser;
    
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      String username = 'User';
      String email = user.email ?? '';
      String photoUrl = '';
      
      // ✅ Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        
        // ✅ Try multiple field names for username
        username = data['name'] ?? data['username'] ?? user.displayName ?? '';
        
        // ✅ Try multiple field names for photo URL (photoUrl, photo_url, photoURL)
        photoUrl = data['photoUrl'] ?? data['photo_url'] ?? data['photoURL'] ?? user.photoURL ?? '';
        
        debugPrint('📸 User photo URL from Firestore: $photoUrl');
      } else {
        username = user.displayName ?? '';
        photoUrl = user.photoURL ?? '';
        debugPrint('⚠️ User doc not found, using Firebase Auth data');
      }
      
      // ✅ Fallback username if empty
      if (username.isEmpty || username == 'null') {
        if (email.isNotEmpty) {
          username = email.split('@')[0];
        } else {
          username = 'User${user.uid.substring(0, user.uid.length > 6 ? 6 : user.uid.length)}';
        }
      }
      
      debugPrint('✅ User Info Retrieved:');
      debugPrint('   UserId: ${user.uid}');
      debugPrint('   Username: $username');
      debugPrint('   PhotoUrl: ${photoUrl.isNotEmpty ? photoUrl : "EMPTY"}');
      
      return {
        'userId': user.uid,
        'username': username,
        'userEmail': email,
        'userPhotoUrl': photoUrl,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting user info: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // ✅ Fallback with basic info
      String fallbackUsername = user.displayName ?? user.email?.split('@')[0] ?? 'User${user.uid.substring(0, user.uid.length > 6 ? 6 : user.uid.length)}';
      
      return {
        'userId': user.uid,
        'username': fallbackUsername,
        'userEmail': user.email ?? '',
        'userPhotoUrl': user.photoURL ?? '',
      };
    }
  }

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data()?['role'] == 'admin';
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }

  Future<bool> isPostOwner(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data()!;
      final postOwnerId = postData['userId'] as String?;

      return postOwnerId == user.uid;
    } catch (e) {
      debugPrint('❌ Error checking post ownership: $e');
      return false;
    }
  }

  Future<void> createPost({
    required String brand,
    required String content,
    required String description,
    String? title,
    String? mainCategory,
    String? subCategory,
    File? imageFile,
    List<PostLink> links = const [],
  }) async {
    final userInfo = await getCurrentUserInfo();

    String? imageUrl;
    
    if (imageFile != null) {
      try {
        debugPrint('📤 Uploading image to Supabase...');
        imageUrl = await _storage.uploadCommunityPostImage(
          imageFile,
          userInfo['userId']!,
        );
        debugPrint('✅ Image uploaded: $imageUrl');
      } catch (e) {
        debugPrint('❌ Image upload failed: $e');
        throw Exception('Failed to upload image: $e');
      }
    }

    final photoUrl = userInfo['userPhotoUrl'] ?? '';
    
    if (photoUrl.isEmpty) {
      debugPrint('⚠️ WARNING: Creating post without user photo!');
    }

    final postData = {
      'brand': brand,
      'title': title ?? '',                    
      'content': content,                      
      'description': description,           
      'mainCategory': mainCategory ?? '',
      'subCategory': subCategory ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl1': imageUrl,
      'links': links.map((link) => link.toMap()).toList(),
      'userId': userInfo['userId'],
      'username': userInfo['username'],
      'userEmail': userInfo['userEmail'],
      'userPhotoUrl': photoUrl,
    };
    
    debugPrint('📝 Creating post with data:');
    debugPrint('   Brand: ${postData['brand']}');
    debugPrint('   Title: ${postData['title']}');
    debugPrint('   Content (Price): ${postData['content']}'); 
    debugPrint('   Description: ${postData['description']}');
    debugPrint('   MainCategory: ${postData['mainCategory']}');
    debugPrint('   SubCategory: ${postData['subCategory']}');
    debugPrint('   Username: ${postData['username']}');
    debugPrint('   UserPhotoUrl: ${postData['userPhotoUrl']}');
    debugPrint('   ImageUrl1: ${imageUrl ?? "No image"}');
    debugPrint('   Links Count: ${links.length}');

    await _firestore.collection('posts').add(postData);

    debugPrint('✅ Post created successfully in Firestore');
  }

  Future<void> createAdminPost({
    required String brand,
    required String content,
    required String description,
    String? title,
    String? mainCategory,
    String? subCategory,
    File? imageFile,
    List<PostLink> links = const [],
  }) async {
    try {
      final userInfo = await getCurrentUserInfo();

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storage.uploadCommunityPostImage(
          imageFile,
          userInfo['userId']!,
        );
      }

      await _firestore.collection('posts').add({
        'brand': brand,
        'title': title ?? content,
        'content': content,
        'description': description,
        'mainCategory': mainCategory ?? '',
        'subCategory': subCategory ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl1': imageUrl,
        'links': links.map((link) => link.toMap()).toList(),
        'userId': userInfo['userId'],
        'username': userInfo['username'],
        'userEmail': userInfo['userEmail'],
        'userPhotoUrl': userInfo['userPhotoUrl'],
      });

      debugPrint('✅ Admin post created for brand: $brand');
    } catch (e) {
      debugPrint('❌ Error creating admin post: $e');
      rethrow;
    }
  }

  Future<void> updatePost({
    required String postId,
    String? title,
    String? content,
    String? description,
    String? mainCategory,
    String? subCategory,
    File? newImageFile,
    String? existingImageUrl,
    List<PostLink>? links,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final postDoc = await _firestore.collection('posts').doc(postId).get();
    
    if (!postDoc.exists) {
      throw Exception('Post not found'); 
    }

    final postData = postDoc.data()!;
    final postOwnerId = postData['userId'] as String?;

    final userIsAdmin = await isAdmin();

    if (postOwnerId != user.uid && !userIsAdmin) {
      throw Exception('You can only edit your own posts');
    }

    final updateData = <String, dynamic>{};
    if (title != null) updateData['title'] = title;
    if (content != null) updateData['content'] = content;
    if (description != null) updateData['description'] = description;
    if (mainCategory != null) updateData['mainCategory'] = mainCategory;
    if (subCategory != null) updateData['subCategory'] = subCategory;
    if (links != null) updateData['links'] = links.map((link) => link.toMap()).toList();
    
    String? finalImageUrl = existingImageUrl;
    
    if (newImageFile != null) {
      try {
        debugPrint('📤 Uploading new image to Supabase...');
        
        if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
          debugPrint('🗑️ Deleting old image...');
          await _storage.deleteImage(existingImageUrl);
        }
        
        finalImageUrl = await _storage.uploadCommunityPostImage(
          newImageFile,
          user.uid,
        );
        debugPrint('✅ New image uploaded: $finalImageUrl');
      } catch (e) {
        debugPrint('❌ Error uploading new image: $e');
        throw Exception('Failed to upload new image: $e');
      }
    }
    
    updateData['imageUrl1'] = finalImageUrl;
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    debugPrint('📝 UPDATE DATA:');
    debugPrint('   Title: ${updateData['title']}');
    debugPrint('   Content: ${updateData['content']}');
    debugPrint('   MainCategory: ${updateData['mainCategory']}');
    debugPrint('   SubCategory: ${updateData['subCategory']}');

    await _firestore.collection('posts').doc(postId).update(updateData);
    debugPrint('✅ Post updated: $postId');
  }

  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final postDoc = await _firestore.collection('posts').doc(postId).get();
    
    if (!postDoc.exists) {
      throw Exception('Post not found');
    }

    final postData = postDoc.data()!;
    final postOwnerId = postData['userId'] as String?;

    final userIsAdmin = await isAdmin();

    if (postOwnerId != user.uid && !userIsAdmin) {
      throw Exception('You can only delete your own posts');
    }

    final imageUrl = postData['imageUrl1'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        debugPrint('🗑️ Deleting image from Supabase...');
        await _storage.deleteImage(imageUrl);
        debugPrint('✅ Image deleted from Supabase');
      } catch (e) {
        debugPrint('⚠️ Error deleting image: $e');
      }
    }

    await _firestore.collection('posts').doc(postId).delete();
    debugPrint('✅ Post deleted: $postId');
  }

  Stream<List<CommunityPost>> getAllPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      
      debugPrint('📦 Total documents: ${snapshot.docs.length}');
      
      List<CommunityPost> posts = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final post = CommunityPost.fromMap(data, doc.id);
          posts.add(post);
        } catch (e, stackTrace) {
          debugPrint('❌ ERROR parsing post ${doc.id}: $e');
          debugPrint(stackTrace.toString());
        }
      }
      
      return posts;
    });
  }

  Stream<List<CommunityPost>> getPostsByBrand(String brand) {
    return _firestore
        .collection('posts')
        .where('brand', isEqualTo: brand)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      
      List<CommunityPost> posts = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final post = CommunityPost.fromMap(data, doc.id);
          posts.add(post);
        } catch (e) {
          debugPrint('❌ ERROR parsing post ${doc.id}: $e');
        }
      }
      
      return posts;
    });
  }

  // ✅ FIXED: Add comment dengan userPhotoUrl yang benar
  Future<void> addComment({
    required String postId,
    required String comment,
  }) async {
    try {
      final userInfo = await getCurrentUserInfo();
      
      final photoUrl = userInfo['userPhotoUrl'] ?? '';
      
      debugPrint('💬 Adding comment:');
      debugPrint('   PostId: $postId');
      debugPrint('   UserId: ${userInfo['userId']}');
      debugPrint('   Username: ${userInfo['username']}');
      debugPrint('   UserPhotoUrl: ${photoUrl.isNotEmpty ? photoUrl : "EMPTY"}');
      debugPrint('   Comment: $comment');

      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': userInfo['userId'],
        'username': userInfo['username'],
        'userPhotoUrl': photoUrl, // ✅ Pastikan field name konsisten
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Comment added successfully to post: $postId');
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding comment: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          debugPrint('📦 Comments loaded: ${snapshot.docs.length}');
          
          return snapshot.docs.map((doc) {
            final data = doc.data();
            debugPrint('💬 Comment data: userId=${data['userId']}, username=${data['username']}, photoUrl=${data['userPhotoUrl']}');
            return Comment.fromMap(data, doc.id);
          }).toList();
        });
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final commentDoc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .get();
    
    if (!commentDoc.exists) {
      throw Exception('Comment not found');
    }

    final commentData = commentDoc.data()!;
    final commentOwnerId = commentData['userId'] as String?;

    final userIsAdmin = await isAdmin();

    if (commentOwnerId != user.uid && !userIsAdmin) {
      throw Exception('You can only delete your own comments');
    }

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
    
    debugPrint('✅ Comment deleted: $commentId from post: $postId');
  }

  Future<bool> isCommentOwner(String postId, String commentId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final commentDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .get();
      
      if (!commentDoc.exists) return false;

      final commentData = commentDoc.data()!;
      final commentOwnerId = commentData['userId'] as String?;

      return commentOwnerId == user.uid;
    } catch (e) {
      debugPrint('❌ Error checking comment ownership: $e');
      return false;
    }
  }

  Future<void> markCommunityAsVisited() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'lastCommunityVisit': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('✅ Community marked as visited');
    } catch (e) {
      debugPrint('❌ Error marking community as visited: $e');
    }
  }

  Future<void> markBrandPostsAsRead(String brand) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'lastBrandVisits': {
          brand: FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
      
      debugPrint('✅ Brand "$brand" posts marked as read');
    } catch (e) {
      debugPrint('❌ Error marking brand posts as read: $e');
    }
  }

  Future<int> getUnreadPostsCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists || userDoc.data() == null) {
        return 0;
      }

      final lastVisit = userDoc.data()!['lastCommunityVisit'] as Timestamp?;
      
      if (lastVisit == null) {
        final postsSnapshot = await _firestore.collection('posts').get();
        return postsSnapshot.docs.length;
      }

      final unreadPosts = await _firestore
          .collection('posts')
          .where('createdAt', isGreaterThan: lastVisit)
          .get();

      return unreadPosts.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting unread posts count: $e');
      return 0;
    }
  }

  Future<int> getUnreadBrandPostsCount(String brand) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists || userDoc.data() == null) {
        return 0;
      }

      final lastBrandVisits = userDoc.data()!['lastBrandVisits'] as Map<String, dynamic>?;
      final lastVisit = lastBrandVisits?[brand] as Timestamp?;
      
      if (lastVisit == null) {
        final postsSnapshot = await _firestore
            .collection('posts')
            .where('brand', isEqualTo: brand)
            .get();
        return postsSnapshot.docs.length;
      }

      final unreadPosts = await _firestore
          .collection('posts')
          .where('brand', isEqualTo: brand)
          .where('createdAt', isGreaterThan: lastVisit)
          .get();

      return unreadPosts.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting unread brand posts count: $e');
      return 0;
    }
  }

  Stream<int> getUnreadPostsCountStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore.collection('users').doc(user.uid).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data() == null) {
        return 0;
      }

      final lastVisit = userDoc.data()!['lastCommunityVisit'] as Timestamp?;
      
      if (lastVisit == null) {
        final postsSnapshot = await _firestore.collection('posts').get();
        return postsSnapshot.docs.length;
      }

      final unreadPosts = await _firestore
          .collection('posts')
          .where('createdAt', isGreaterThan: lastVisit)
          .get();

      return unreadPosts.docs.length;
    });
  }

  Stream<int> getUnreadBrandPostsCountStream(String brand) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore.collection('users').doc(user.uid).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data() == null) {
        return 0;
      }

      final lastBrandVisits = userDoc.data()!['lastBrandVisits'] as Map<String, dynamic>?;
      final lastVisit = lastBrandVisits?[brand] as Timestamp?;
      
      if (lastVisit == null) {
        final postsSnapshot = await _firestore
            .collection('posts')
            .where('brand', isEqualTo: brand)
            .get();
        return postsSnapshot.docs.length;
      }

      final unreadPosts = await _firestore
          .collection('posts')
          .where('brand', isEqualTo: brand)
          .where('createdAt', isGreaterThan: lastVisit)
          .get();

      return unreadPosts.docs.length;
    });
  }
}