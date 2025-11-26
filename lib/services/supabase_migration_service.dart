import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  static const String bucketName = 'Primez_Sports';

  Future<void> migrateAllPosts() async {
    try {
      debugPrint('🚀 Starting posts migration to Supabase Storage...');
      
      final postsSnapshot = await _firestore.collection('posts').get();
      debugPrint('📦 Found ${postsSnapshot.docs.length} posts to migrate');

      int success = 0;
      int failed = 0;
      int skipped = 0;

      for (var doc in postsSnapshot.docs) {
        try {
          final data = doc.data();
          bool needsUpdate = false;
          Map<String, dynamic> updates = {};

          if (data['userPhotoUrl'] != null && 
              data['userPhotoUrl'].toString().startsWith('data:image')) {
            final newUrl = await _migrateBase64ToSupabase(
              base64String: data['userPhotoUrl'],
              folder: 'migration/avatars', 
              userId: data['userId'] ?? 'unknown',
              docId: doc.id,
              fieldName: 'userPhotoUrl',
            );
            
            if (newUrl != null) {
              updates['userPhotoUrl'] = newUrl;
              needsUpdate = true;
            }
          } else if (data['userPhotoUrl'] != null && 
                     data['userPhotoUrl'].toString().startsWith('http')) {
            skipped++;
          }

          if (data['imageUrl1'] != null && 
              data['imageUrl1'].toString().startsWith('data:image')) {
            final newUrl = await _migrateBase64ToSupabase(
              base64String: data['imageUrl1'],
              folder: 'migration/posts',
              userId: data['userId'] ?? 'unknown',
              docId: doc.id,
              fieldName: 'imageUrl1',
            );
            
            if (newUrl != null) {
              updates['imageUrl1'] = newUrl;
              needsUpdate = true;
            }
          } else if (data['imageUrl1'] != null && 
                     data['imageUrl1'].toString().startsWith('http')) {
            skipped++;
          }

          if (needsUpdate) {
            await doc.reference.update(updates);
            success++;
            debugPrint('✅ Migrated post ${doc.id}');
          }

        } catch (e) {
          failed++;
          debugPrint('❌ Failed to migrate post ${doc.id}: $e');
        }
      }

      debugPrint('');
      debugPrint('✨ Posts migration completed!');
      debugPrint('✅ Success: $success');
      debugPrint('❌ Failed: $failed');
      debugPrint('⏭️ Skipped: $skipped');
      
    } catch (e) {
      debugPrint('❌ Posts migration error: $e');
      rethrow;
    }
  }

  Future<String?> _migrateBase64ToSupabase({
    required String base64String,
    required String folder,
    required String userId,
    required String docId,
    required String fieldName,
  }) async {
    try {
      final bytes = _decodeBase64(base64String);
      if (bytes == null) {
        debugPrint('⚠️ Failed to decode base64 for $docId/$fieldName');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_${docId}_$timestamp.jpg';
      final filePath = '$folder/$fileName';

      await _supabase.storage.from(bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);

      debugPrint('  ✓ Uploaded $fieldName to $filePath');
      
      return publicUrl;
    } catch (e) {
      debugPrint('  ✗ Error uploading $fieldName: $e');
      return null;
    }
  }

  Uint8List? _decodeBase64(String src) {
    try {
      String cleaned = src
          .replaceAll("\n", "")
          .replaceAll("\r", "")
          .replaceAll(" ", "")
          .trim();

      if (cleaned.contains(",")) {
        cleaned = cleaned.split(",").last;
      }

      return base64Decode(cleaned);
    } catch (e) {
      debugPrint('⚠️ Base64 decode error: $e');
      return null;
    }
  }

  Future<void> migrateAllUsers() async {
    try {
      debugPrint('🚀 Starting users migration...');
      
      final usersSnapshot = await _firestore.collection('users').get();
      debugPrint('📦 Found ${usersSnapshot.docs.length} users to migrate');

      int success = 0;
      int failed = 0;
      int skipped = 0;

      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data();

          String? photoToMigrate;
          
          if (data['photoUrl'] != null && 
              data['photoUrl'].toString().startsWith('data:image')) {
            photoToMigrate = data['photoUrl'];
          } else if (data['photoBase64'] != null && 
                     data['photoBase64'].toString().startsWith('data:image')) {
            photoToMigrate = data['photoBase64'];
          } else if ((data['photoUrl'] != null && 
                      data['photoUrl'].toString().startsWith('http')) ||
                     (data['photoBase64'] != null && 
                      data['photoBase64'].toString().startsWith('http'))) {
            skipped++;
            continue;
          }

          if (photoToMigrate != null) {
            final newUrl = await _migrateBase64ToSupabase(
              base64String: photoToMigrate,
              folder: 'migration/avatars', 
              userId: doc.id,
              docId: doc.id,
              fieldName: 'photoUrl',
            );
            
            if (newUrl != null) {
              await doc.reference.update({
                'photoUrl': newUrl,
                'photoBase64': FieldValue.delete(),
              });
              success++;
              debugPrint('✅ Migrated user ${doc.id}');
            }
          }

        } catch (e) {
          failed++;
          debugPrint('❌ Failed to migrate user ${doc.id}: $e');
        }
      }

      debugPrint('');
      debugPrint('✨ Users migration completed!');
      debugPrint('✅ Success: $success');
      debugPrint('❌ Failed: $failed');
      debugPrint('⏭️ Skipped: $skipped');
      
    } catch (e) {
      debugPrint('❌ Users migration error: $e');
      rethrow;
    }
  }

  Future<void> runFullMigration() async {
    debugPrint('🚀🚀🚀 STARTING FULL MIGRATION TO SUPABASE 🚀🚀🚀');
    debugPrint('');
    
    try {
      debugPrint('🔍 Testing Supabase connection...');
      final testList = await _supabase.storage
          .from(bucketName)
          .list(path: '', searchOptions: const SearchOptions(limit: 1));
      debugPrint('✅ Supabase connection OK');
      debugPrint('');
      
      await migrateAllPosts();
      debugPrint('');
      await migrateAllUsers();
      
      debugPrint('');
      debugPrint('🎉🎉🎉 FULL MIGRATION COMPLETED 🎉🎉🎉');
    } catch (e) {
      debugPrint('❌ Error migrating to Supabase: $e');
      rethrow;
    }
  }
}