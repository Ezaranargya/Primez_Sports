import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageService {
  final _supabase = Supabase.instance.client;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ User belum login');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = '${timestamp}_${userId.substring(0, 8)}$extension';

      final storagePath = '$userId/$folder/$fileName';

      print('📤 Uploading ke Supabase: $storagePath');

      await _supabase.storage
          .from('Primez_Sports')
          .upload(storagePath, imageFile);

      final imageUrl = _supabase.storage
          .from('Primez_Sports')
          .getPublicUrl(storagePath);

      print('✅ Upload berhasil: $imageUrl');

      final docRef = await _firestore.collection('images').add({
        'imageUrl': imageUrl,
        'storagePath': storagePath,
        'userId': userId,
        'folder': folder,
        'uploadedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      });

      print('✅ Metadata tersimpan di Firestore dengan ID: ${docRef.id}');

      return docRef.id; 

    } on StorageException catch (e) {
      print('❌ Supabase Storage Error: ${e.message}');
      return null;
    } catch (e, stackTrace) {
      print('❌ Upload Error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<bool> deleteImage(String imageDocId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ User belum login');
        return false;
      }

      final doc = await _firestore.collection('images').doc(imageDocId).get();

      if (!doc.exists) {
        print('❌ Dokumen gambar tidak ditemukan');
        return false;
      }

      final data = doc.data()!;

      if (data['userId'] != userId) {
        print('❌ Bukan pemilik gambar ini');
        return false;
      }

      final storagePath = data['storagePath'] as String;

      await _supabase.storage
          .from('Primez_Sports')
          .remove([storagePath]);

      print('✅ File dihapus dari Supabase: $storagePath');

      await _firestore.collection('images').doc(imageDocId).delete();

      print('✅ Metadata dihapus dari Firestore');

      return true;

    } on StorageException catch (e) {
      print('❌ Supabase Storage Error: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Delete Error: $e');
      return false;
    }
  }

  Future<bool> updateImage({
    required String imageDocId,
    required File newImageFile,
  }) async {
    try {
      final doc = await _firestore.collection('images').doc(imageDocId).get();

      if (!doc.exists) {
        print('❌ Gambar tidak ditemukan');
        return false;
      }

      final data = doc.data()!;
      final folder = data['folder'] as String;
      final oldStoragePath = data['storagePath'] as String;

      final newDocId = await uploadImage(
        imageFile: newImageFile,
        folder: folder,
        additionalData: {
          'replacedFrom': imageDocId, 
        },
      );

      if (newDocId == null) {
        print('❌ Gagal upload gambar baru');
        return false;
      }

      await _supabase.storage.from('Primez_Sports').remove([oldStoragePath]);

      await _firestore.collection('images').doc(imageDocId).delete();

      print('✅ Gambar berhasil diupdate');
      return true;

    } catch (e) {
      print('❌ Update Error: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> getUserImages({String? folder}) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User belum login');

    Query query = _firestore
        .collection('images')
        .where('userId', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true);

    if (folder != null) {
      query = query.where('folder', isEqualTo: folder);
    }

    return query.snapshots();
  }

  Future<Map<String, dynamic>?> getImage(String imageDocId) async {
    try {
      final doc = await _firestore.collection('images').doc(imageDocId).get();

      if (!doc.exists) return null;

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      print('❌ Get Image Error: $e');
      return null;
    }
  }

  Future<String?> pickAndUploadImage({
    required String folder,
    ImageSource source = ImageSource.gallery,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('⚠️ User membatalkan pick image');
        return null;
      }

      final imageFile = File(pickedFile.path);

      return await uploadImage(
        imageFile: imageFile,
        folder: folder,
        additionalData: additionalData,
      );

    } catch (e) {
      print('❌ Pick & Upload Error: $e');
      return null;
    }
  }

  Future<void> deleteAllImagesInFolder(String folder) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('images')
          .where('userId', isEqualTo: userId)
          .where('folder', isEqualTo: folder)
          .get();

      for (var doc in snapshot.docs) {
        await deleteImage(doc.id);
      }

      print('✅ Semua gambar di folder "$folder" berhasil dihapus');
    } catch (e) {
      print('❌ Batch Delete Error: $e');
    }
  }
}

class ImageUploadExample extends StatefulWidget {
  const ImageUploadExample({super.key});

  @override
  State<ImageUploadExample> createState() => _ImageUploadExampleState();
}

class _ImageUploadExampleState extends State<ImageUploadExample> {
  final _imageService = ImageService();
  bool _isUploading = false;

  Future<void> _uploadProfilePicture() async {
    setState(() => _isUploading = true);

    final docId = await _imageService.pickAndUploadImage(
      folder: 'profiles',
      source: ImageSource.gallery,
      additionalData: {
        'type': 'profile_picture',
        'description': 'Foto profil user',
      },
    );

    setState(() => _isUploading = false);

    if (docId != null && mounted) {
      final imageData = await _imageService.getImage(docId);
      final imageUrl = imageData?['imageUrl'];

      final userId = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'profilePicture': imageUrl,
        'profilePictureDocId': docId, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Foto profil berhasil diupload')),
        );
      }
    }
  }

  Future<void> _uploadPostImage() async {
    final docId = await _imageService.pickAndUploadImage(
      folder: 'posts',
      source: ImageSource.camera,
      additionalData: {
        'type': 'post_image',
      },
    );

    if (docId != null && mounted) {
      final imageData = await _imageService.getImage(docId);
      final imageUrl = imageData?['imageUrl'];

      await FirebaseFirestore.instance.collection('posts').add({
        'imageUrl': imageUrl,
        'imageDocId': docId,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'caption': 'Post caption here',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Post berhasil dibuat')),
        );
      }
    }
  }

  Future<void> _deleteImage(String docId) async {
    final success = await _imageService.deleteImage(docId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Gambar berhasil dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Gambar')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadProfilePicture,
            child: const Text('Upload Foto Profil'),
          ),

          ElevatedButton(
            onPressed: _uploadPostImage,
            child: const Text('Upload Post Image'),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _imageService.getUserImages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final images = snapshot.data!.docs;

                if (images.isEmpty) {
                  return const Center(
                    child: Text('Belum ada gambar'),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final doc = images[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final imageUrl = data['imageUrl'] as String;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.error),
                            );
                          },
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteImage(doc.id),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}