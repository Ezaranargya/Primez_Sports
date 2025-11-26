import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  static const String bucketName = 'Primez_Sports';

  Future<void> register(String email, String password, String role) async {
    firebase_auth.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password,
    );

    firebase_auth.User? user = userCredential.user;

    String username = email.split('@')[0];

    await _firestore.collection("users").doc(user!.uid).set({
      "uid": user.uid,
      "email": email,
      "role": role,
      "status": "active",
      "name": username,
      "username": username,
      "photoUrl": "",  
      "profile": "", 
      "createdAt": FieldValue.serverTimestamp(),
    });
    
    debugPrint('✅ User registered with username: $username');
  }

  Future<String?> login(String email, String password) async {
    firebase_auth.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password,
    );
    firebase_auth.User? user = userCredential.user;
    
    await syncUserToFirestore();
    
    DocumentSnapshot snapshot = await _firestore.collection("users").doc(user!.uid).get();

    return snapshot["role"];
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  firebase_auth.User? get currentUser => _auth.currentUser;

  Future<void> syncUserToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ No user logged in');
      return;
    }

    try {
      debugPrint('🔄 Syncing user to Firestore...');
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      String username = '';
      String photoUrl = '';
      
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        
        username = data['name'] ?? data['username'] ?? user.displayName ?? '';
        
        photoUrl = data['photoUrl'] ?? user.photoURL ?? '';
        
        if (data.containsKey('photoBase64') && data['photoBase64'] != null && data['photoBase64'].toString().isNotEmpty) {
          debugPrint('🔄 Migrating base64 photo to Supabase Storage...');
          try {
            final base64Data = data['photoBase64'] as String;
            final supabaseUrl = await _migrateBase64ToSupabase(user.uid, base64Data);
            if (supabaseUrl != null) {
              photoUrl = supabaseUrl;
              await _firestore.collection('users').doc(user.uid).update({
                'photoUrl': photoUrl,
                'photoBase64': FieldValue.delete(),
              });
              debugPrint('✅ Photo migrated to Supabase Storage');
            }
          } catch (e) {
            debugPrint('❌ Error migrating photo: $e');
          }
        }
      } else {
        username = user.displayName ?? '';
        photoUrl = user.photoURL ?? '';
      }
      
      if (username.isEmpty || username == 'null') {
        if (user.email != null && user.email!.isNotEmpty) {
          username = user.email!.split('@')[0];
        } else {
          username = 'User${user.uid.substring(0, 6)}';
        }
      }

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': username,
        'username': username,
        'email': user.email ?? '',
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ User synced to Firestore');
      debugPrint('   Username: "$username"');
      debugPrint('   Email: "${user.email}"');
      debugPrint('   PhotoUrl: "${photoUrl.isEmpty ? "empty" : "has data"}"');
    } catch (e) {
      debugPrint('❌ Error syncing user to Firestore: $e');
    }
  }

  Future<String?> _migrateBase64ToSupabase(String userId, String base64Data) async {
    try {
      String cleanedBase64 = base64Data;
      if (base64Data.contains('base64,')) {
        cleanedBase64 = base64Data.split('base64,')[1];
      }

      final bytes = base64Decode(cleanedBase64);

      final fileName = 'profile_$userId.jpg';
      final path = 'profiles/$fileName';

      await _supabase.storage
          .from('Primez_Sports')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from('Primez_Sports')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error migrating to Supabase: $e');
      return null;
    }
  }

  Future<void> updateUsername(String newUsername) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': newUsername,
        'username': newUsername,
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

  Future<void> updatePhotoUrl(String photoData, {bool isBase64 = false}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    String finalPhotoUrl = photoData;

    try {
      if (isBase64 && photoData.isNotEmpty) {
        debugPrint('📤 Uploading base64 photo to Supabase Storage...');
        
        String cleanedBase64 = photoData;
        if (photoData.contains('base64,')) {
          cleanedBase64 = photoData.split('base64,')[1];
        }
        final bytes = base64Decode(cleanedBase64);
        
        finalPhotoUrl = await _uploadPhotoBytesToSupabase(user.uid, bytes);
      } else if (!isBase64 && photoData.isEmpty) {
        await removeProfilePhoto();
        return;
      }
      
      if (finalPhotoUrl.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).set({
          'photoUrl': finalPhotoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await user.updatePhotoURL(finalPhotoUrl);
        
        debugPrint('✅ Photo URL updated: $finalPhotoUrl');
      }

      await _updatePhotoInPosts(user.uid, finalPhotoUrl);
    } catch (e) {
      debugPrint('❌ Error updating photo URL: $e');
      rethrow;
    }
  }

  Future<String> _uploadPhotoToSupabase(String userId, File imageFile) async {
    try {
      final fileName = 'profile_$userId.jpg';
      final path = 'profiles/$fileName';

      await _supabase.storage
          .from('Primez_Sports')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from('Primez_Sports')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading to Supabase: $e');
      rethrow;
    }
  }

  Future<String> _uploadPhotoBytesToSupabase(String userId, Uint8List bytes) async {
  try {
    final fileName = 'profile_$userId.jpg';
    final path = 'profiles/$fileName';

    debugPrint('📤 [UPLOAD] Starting upload...');
    debugPrint('📤 [UPLOAD] Bucket: Primez_Sports');
    debugPrint('📤 [UPLOAD] Path: $path');
    debugPrint('📤 [UPLOAD] File size: ${bytes.length} bytes');

    final response = await _supabase.storage
        .from('Primez_Sports')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    debugPrint('✅ [UPLOAD] Upload successful!');
    debugPrint('✅ [UPLOAD] Response: $response');

    final publicUrl = _supabase.storage
        .from('Primez_Sports')
        .getPublicUrl(path);

    debugPrint('✅ [UPLOAD] Public URL: $publicUrl');
    
    return publicUrl;
  } catch (e, stackTrace) {
    debugPrint('❌ [UPLOAD] Error: $e');
    debugPrint('❌ [UPLOAD] Type: ${e.runtimeType}');
    debugPrint('📍 [UPLOAD] Stack trace: $stackTrace');
    rethrow;
  }
}

  Future<void> updatePhotoFromFile(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      debugPrint('📤 Uploading photo to Supabase Storage...');
      
      final photoUrl = await _uploadPhotoToSupabase(user.uid, imageFile);

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.updatePhotoURL(photoUrl);
      
      debugPrint('✅ Photo URL updated: $photoUrl');
      
      await _updatePhotoInPosts(user.uid, photoUrl);
    } catch (e) {
      debugPrint('❌ Error updating photo: $e');
      rethrow;
    }
  }

  Future<void> updatePhotoFromBytes(Uint8List bytes) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      debugPrint('📤 Uploading photo to Supabase Storage...');
      
      final photoUrl = await _uploadPhotoBytesToSupabase(user.uid, bytes);

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.updatePhotoURL(photoUrl);
      
      debugPrint('✅ Photo URL updated: $photoUrl');
      
      await _updatePhotoInPosts(user.uid, photoUrl);
    } catch (e) {
      debugPrint('❌ Error updating photo: $e');
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

  Future<void> _updatePhotoInPosts(String userId, String photoUrl) async {
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
        }
      }

      if (count % 500 != 0) {
        await batch.commit();
      }

      debugPrint('✅ Updated photo in $count posts');
    } catch (e) {
      debugPrint('❌ Error updating photo in posts: $e');
    }
  }

  Future<void> removeProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      try {
        final fileName = 'profile_${user.uid}.jpg';
        final path = 'profiles/$fileName';
        
        await _supabase.storage
            .from('Primez_Sports')
            .remove([path]);
        
        debugPrint('✅ Photo deleted from Supabase Storage');
      } catch (e) {
        debugPrint('⚠️ Error deleting from Supabase (might not exist): $e');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.updatePhotoURL(null);

      debugPrint('✅ Profile photo removed');

      await _updatePhotoInPosts(user.uid, '');
      
    } catch (e) {
      debugPrint('❌ Error removing profile photo: $e');
      rethrow;
    }
  }
}