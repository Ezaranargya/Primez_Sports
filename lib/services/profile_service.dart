import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  SupabaseClient get _supabase => Supabase.instance.client;
  static const String bucketName = 'Primez_Sports';

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user logged in');
        return null;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        debugPrint('❌ User document not found');
        return null;
      }

      final data = doc.data()!;
      return {
        'uid': user.uid,
        'username': data['username'] ?? data['name'] ?? 'User',
        'email': data['email'] ?? user.email ?? '',
        'photoUrl': data['photoUrl'] ?? '',
        'photoPath': data['photoPath'] ?? '',
        'bio': data['bio'] ?? '',
      };
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return null;
    }
  }

  Future<void> updateUsername(String newUsername) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'username': newUsername,
        'name': newUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.updateDisplayName(newUsername);

      debugPrint('✅ Username updated to: $newUsername');
      
      await _updateUsernameInPosts(user.uid, newUsername);
    } catch (e) {
      debugPrint('❌ Error updating username: $e');
      rethrow;
    }
  }

  Future<Uint8List?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) {
        debugPrint('⚠️ User cancelled image selection');
        return null;
      }

      final bytes = await image.readAsBytes();
      debugPrint('✅ Image picked: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  Future<void> updateProfilePhoto(Uint8List imageBytes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      debugPrint('📤 Starting profile photo upload...');
      debugPrint('   User ID: ${user.uid}');
      debugPrint('   Image size: ${imageBytes.length} bytes');
      debugPrint('   Bucket: $bucketName');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${user.uid}_$timestamp.jpg';
      final path = 'profiles/$fileName';

      debugPrint('📤 Uploading to: $path');

      try {
        await _supabase.storage
            .from(bucketName)
            .uploadBinary(
              path,
              imageBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        
        debugPrint('✅ Upload to Supabase successful');
      } catch (storageError) {
        debugPrint('❌ Supabase upload failed: $storageError');
        throw Exception('Gagal upload foto ke Supabase Storage: $storageError');
      }

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      debugPrint('✅ Public URL generated: $publicUrl');

      try {
        final oldDoc = await _firestore.collection('users').doc(user.uid).get();
        final oldPhotoPath = oldDoc.data()?['photoPath'] as String?;
        
        if (oldPhotoPath != null && oldPhotoPath.isNotEmpty) {
          debugPrint('🗑️ Deleting old photo: $oldPhotoPath');
          await _supabase.storage
              .from(bucketName)
              .remove([oldPhotoPath]);
          debugPrint('✅ Old photo deleted');
        }
      } catch (e) {
        debugPrint('⚠️ Could not delete old photo: $e');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': publicUrl,
        'photoPath': path,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Firestore updated');

      try {
        await user.updatePhotoURL(publicUrl);
        debugPrint('✅ Firebase Auth photo updated');
      } catch (e) {
        debugPrint('⚠️ Could not update Firebase Auth photoURL: $e');
      }

      debugPrint('🔄 Updating photo in user posts...');
      await _updateUserPostsPhoto(user.uid, publicUrl);

      debugPrint('✅ Profile photo update completed successfully!');
    } catch (e) {
      debugPrint('❌ Error updating profile photo: $e');
      rethrow;
    }
  }

  Future<void> _updateUsernameInPosts(String userId, String newUsername) async {
    try {
      debugPrint('🔄 Updating username in all user posts...');

      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      if (postsSnapshot.docs.isEmpty) {
        debugPrint('   No posts to update');
        return;
      }

      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in postsSnapshot.docs) {
        batch.update(doc.reference, {
          'username': newUsername,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        count++;

        if (count % 500 == 0) {
          await batch.commit();
          batch = _firestore.batch();
          debugPrint('   Updated $count posts...');
        }
      }

      if (count % 500 != 0) {
        await batch.commit();
      }

      debugPrint('✅ Updated username in $count posts');
    } catch (e) {
      debugPrint('❌ Error updating username in posts: $e');
    }
  }

  Future<void> _updateUserPostsPhoto(String userId, String photoUrl) async {
    try {
      debugPrint('🔄 Updating photo in all user posts...');

      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      if (postsSnapshot.docs.isEmpty) {
        debugPrint('   No posts to update');
        return;
      }

      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in postsSnapshot.docs) {
        batch.update(doc.reference, {
          'userPhotoUrl': photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        count++;

        if (count % 500 == 0) {
          await batch.commit();
          batch = _firestore.batch();
          debugPrint('   Updated $count posts...');
        }
      }

      if (count % 500 != 0) {
        await batch.commit();
      }

      debugPrint('✅ Updated photo in $count posts');
    } catch (e) {
      debugPrint('❌ Error updating posts photo: $e');
    }
  }

  Future<void> removeProfilePhoto() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      debugPrint('🗑️ Removing profile photo...');

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      final data = doc.data();

      final photoPath = data?['photoPath'] as String? ?? '';
      
      if (photoPath.isNotEmpty) {
        try {
          await _supabase.storage
              .from(bucketName)
              .remove([photoPath]);
          debugPrint('✅ Photo deleted from Supabase: $photoPath');
        } catch (e) {
          debugPrint('⚠️ Could not delete photo from Supabase: $e');
        }
      }

      await docRef.update({
        'photoUrl': '',
        'photoPath': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Firestore updated');

      try {
        await user.updatePhotoURL(null);
        debugPrint('✅ Firebase Auth photo cleared');
      } catch (e) {
        debugPrint('⚠️ Could not clear Firebase Auth photoURL: $e');
      }

      await _updateUserPostsPhoto(user.uid, '');

      debugPrint('✅ Profile photo removed successfully!');
    } catch (e) {
      debugPrint('❌ Error removing profile photo: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('✅ User logged out');
    } catch (e) {
      debugPrint('❌ Error logging out: $e');
      rethrow;
    }
  }

  Future<bool> validateSupabaseConnection() async {
    try {
      debugPrint('🔍 Validating Supabase connection...');
      
      final response = await _supabase.storage
          .from(bucketName)
          .list(path: '', searchOptions: const SearchOptions(limit: 1));
      
      debugPrint('✅ Supabase connection valid');
      return true;
    } catch (e) {
      debugPrint('❌ Supabase connection failed: $e');
      return false;
    }
  }

  Future<void> updateBio(String newBio) async {
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection('users').doc(user.uid).update({
      'bio': newBio,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Bio updated: $newBio');

  } catch (e) {
    debugPrint('❌ Error updating bio: $e');
    rethrow;
  }
}
}