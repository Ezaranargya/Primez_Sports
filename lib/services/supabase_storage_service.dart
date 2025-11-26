import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'Primez_Sports';
  
  Future<String?> uploadImage({
    required File file,
    required String bucket,
    required String folder,
    required String userId,
  }) async {
    try {
      debugPrint('📤 Uploading image to Supabase...');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp.jpg';
      final path = '$folder/$fileName';

      await _supabase.storage
          .from(bucket)
          .upload(
            path,
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(path);

      debugPrint('✅ Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  Future<String> uploadImagePositional(File file, String fileName) async {
    try {
      debugPrint('📤 Uploading image to Supabase...');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'products/${fileName}_$timestamp.jpg';

      await _supabase.storage
          .from(bucketName)
          .upload(
            path,
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      debugPrint('✅ Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      rethrow;
    }
  }

  Future<String?> uploadPostImage({
    required File file,
    required String userId,
  }) async {
    try {
      debugPrint('📤 Uploading post image to Supabase...');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp.jpg';
      final path = 'community_posts/$fileName';

      await _supabase.storage
          .from(bucketName)
          .upload(
            path,
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      debugPrint('✅ Post image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading post image: $e');
      return null;
    }
  }

  Future<String?> uploadProductImage(File imageFile, String productId) async {
    try {
      debugPrint('📤 Uploading product image to Supabase...');
      
      final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'products/$fileName';

      await _supabase.storage
          .from(bucketName)
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      debugPrint('✅ Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  Future<String?> uploadProductImageFromBytes(Uint8List bytes, String productId) async {
    try {
      debugPrint('📤 Uploading product image bytes to Supabase...');
      
      final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'products/$fileName';

      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      debugPrint('✅ Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  Future<String?> uploadCommunityPostImage(File imageFile, String userId) async {
    try {
      debugPrint('📤 Uploading community post image to Supabase...');
      
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'community_posts/$fileName';

      await _supabase.storage
          .from(bucketName)
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      debugPrint('✅ Community post image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading community post image: $e');
      return null;
    }
  }

  Future<String?> uploadNewsImage(File imageFile) async {
    try {
      debugPrint('📤 Uploading news image to Supabase...');
      
      final fileName = 'news_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'news/$fileName';

      await _supabase.storage
          .from(bucketName)
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      debugPrint('✅ News image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading news image: $e');
      return null;
    }
  }

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      debugPrint('📤 Uploading profile image to Supabase...');
      
      final fileName = 'profile_${userId}.jpg';
      final path = 'profiles/$fileName';

      await _supabase.storage
          .from(bucketName)
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      debugPrint('✅ Profile image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      return null;
    }
  }

  Future<String?> uploadProfileImageFromBytes(Uint8List bytes, String userId) async {
    try {
      debugPrint('📤 Uploading profile image bytes to Supabase...');
      
      final fileName = 'profile_${userId}.jpg';
      final path = 'profiles/$fileName';

      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      debugPrint('✅ Profile image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      return null;
    }
  }

  Future<String?> uploadUserPhoto({
    File? file,
    Uint8List? bytes,
    required String userId,
    String? fileName,
  }) async {
    try {
      if (file == null && bytes == null) {
        throw Exception('Either file or bytes must be provided');
      }

      debugPrint('📤 Uploading user photo to Supabase...');
      
      final name = 'profile_$userId';
      final path = 'profiles/$name.jpg';

      if (file != null) {
        await _supabase.storage
            .from(bucketName)
            .upload(
              path,
              file,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      } else if (bytes != null) {
        await _supabase.storage
            .from(bucketName)
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      }

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(path);

      debugPrint('✅ User photo uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading user photo: $e');
      return null;
    }
  }

  Future<void> deletePostImage(String imageUrl) async {
    try {
      await deleteImage(imageUrl);
      debugPrint('✅ Post image deleted');
    } catch (e) {
      debugPrint('❌ Error deleting post image: $e');
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      await deleteImage(imageUrl);
      debugPrint('✅ Product image deleted');
    } catch (e) {
      debugPrint('❌ Error deleting product image: $e');
    }
  }

  Future<void> deleteUserPhoto(String userId) async {
    try {
      final path = 'profiles/profile_$userId.jpg';
      
      await _supabase.storage
          .from(bucketName)
          .remove([path]);

      debugPrint('✅ User photo deleted: $path');
    } catch (e) {
      debugPrint('❌ Error deleting user photo: $e');
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex == -1) {
        final objectIndex = pathSegments.indexOf('object');
        if (objectIndex != -1 && objectIndex < pathSegments.length - 2) {
          final filePath = pathSegments.sublist(objectIndex + 2).join('/');
          
          await _supabase.storage
              .from(bucketName)
              .remove([filePath]);

          debugPrint('✅ Image deleted from Supabase Storage: $filePath');
          return true;
        }
        return false;
      }
      
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await _supabase.storage
          .from(bucketName)
          .remove([filePath]);

      debugPrint('✅ Image deleted from Supabase Storage: $filePath');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
      return false;
    }
  }

  Future<bool> deleteProfileImage(String userId) async {
    try {
      final path = 'profiles/profile_$userId.jpg';
      
      await _supabase.storage.from(bucketName).remove([path]);

      debugPrint('✅ Profile image deleted: $path');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting profile image: $e');
      return false;
    }
  }

  String getPublicUrl(String filePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(filePath);
  }

  Future<List<String>> listFiles(String folder) async {
    try {
      final files = await _supabase.storage.from(bucketName).list(path: folder);
      return files.map((file) => file.name).toList();
    } catch (e) {
      debugPrint('❌ Error listing files: $e');
      return [];
    }
  }
}