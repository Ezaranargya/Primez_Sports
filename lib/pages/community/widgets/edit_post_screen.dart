import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/services/community_service.dart';
import 'package:my_app/services/supabase_storage_service.dart'; 
import 'package:my_app/models/community_post_model.dart';
import 'package:my_app/theme/app_colors.dart';

class EditPostScreen extends StatefulWidget {
  final CommunityPost post;

  const EditPostScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _contentController;
  late TextEditingController _descriptionController;
  final _communityService = CommunityService();
  final _storageService = SupabaseStorageService(); 
  final _picker = ImagePicker();

  File? _newImageFile;
  String? _currentImageUrl;
  bool _hasRemovedImage = false;
  bool _isProcessingImage = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    _descriptionController = TextEditingController(text: widget.post.description);
    
    _currentImageUrl = widget.post.imageUrl1;
    
    debugPrint('🔄 EditPost initialized');
    debugPrint('   Post ID: ${widget.post.id}');
    debugPrint('   Has image: ${_currentImageUrl != null && _currentImageUrl!.isNotEmpty}');
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      setState(() {
        _newImageFile = File(pickedFile.path);
        _hasRemovedImage = false;
      });

      debugPrint('📸 New image picked: ${pickedFile.path}');

    } catch (e, stackTrace) {
      debugPrint('❌ Error picking image: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _newImageFile = null;
      });
    }
  }

  void _removeCurrentImage() {
    setState(() {
      _currentImageUrl = null;
      _hasRemovedImage = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gambar akan dihapus saat disimpan'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeNewImage() {
    setState(() {
      _newImageFile = null;
    });
  }

  Future<void> _updatePost() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ User tidak terautentikasi'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deskripsi tidak boleh kosong'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _isProcessingImage = _newImageFile != null;
    });

    try {
      String? finalImageUrl = _currentImageUrl;

      if (_newImageFile != null) {
        debugPrint('🖼️ Uploading new image to Supabase Storage...');
        
        finalImageUrl = await _storageService.uploadPostImage(
          file: _newImageFile!, 
          userId: currentUser.uid,
        );

        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
          await _storageService.deletePostImage(_currentImageUrl!);
          debugPrint('🗑️ Old image deleted from storage');
        }

        if (finalImageUrl == null || finalImageUrl.isEmpty) {
          throw Exception('Gagal mengunggah gambar ke storage');
        }
        
        debugPrint('✅ Image uploaded successfully: $finalImageUrl');
      } 

      else if (_hasRemovedImage && _currentImageUrl != null) {
        debugPrint('🗑️ Removing existing image from storage...');
        await _storageService.deletePostImage(_currentImageUrl!);
        finalImageUrl = null;
        debugPrint('✅ Image successfully removed');
      }
      
      debugPrint('💾 Updating post in Firestore...');
      
      await _communityService.updatePost(
        postId: widget.post.id,
        content: _contentController.text.trim(),
        description: _descriptionController.text.trim(),
        newImageFile: _newImageFile,
      );

      debugPrint('✅ Post updated successfully');

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Postingan berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating post: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isProcessingImage = false;
        });
      }
    }
  }
  
  Widget _buildImage(String imageUrl) {
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 200.h,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 200.h,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Error loading image: $error');
        return _buildImageError();
      },
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 200.h,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 48.sp, color: Colors.grey[400]),
          SizedBox(height: 8.h),
          Text(
            'Gambar tidak dapat dimuat',
            style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showNewImage = _newImageFile != null;
    final bool showCurrentImage = !showNewImage && 
                                   !_hasRemovedImage && 
                                   _currentImageUrl != null && 
                                   _currentImageUrl!.isNotEmpty;
    final bool showImagePicker = !showNewImage && !showCurrentImage;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Postingan',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: (_isUploading || _isProcessingImage) ? null : _updatePost,
            child: (_isUploading || _isProcessingImage)
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.secondary,
                    ),
                  )
                : Text(
                    'Simpan',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.post.brand,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 20.h),

            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Judul postingan...',
                border: OutlineInputBorder(),
                labelText: 'Judul',
              ),
              maxLines: 1,
            ),
            SizedBox(height: 16.h),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Tulis deskripsi...',
                border: OutlineInputBorder(),
                labelText: 'Deskripsi',
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20.h),

            if (_isProcessingImage)
              Container(
                height: 200.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Mengunggah gambar...'),
                    ],
                  ),
                ),
              )
            else if (showNewImage)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.file(
                      _newImageFile!,
                      width: double.infinity,
                      height: 200.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: IconButton(
                      onPressed: _removeNewImage,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.upload_file, color: Colors.white, size: 16),
                          SizedBox(width: 6.w),
                          Text(
                            'Gambar Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else if (showCurrentImage)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: _buildImage(_currentImageUrl!),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: IconButton(
                      onPressed: _removeCurrentImage,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image, color: Colors.white, size: 16),
                          SizedBox(width: 6.w),
                          Text(
                            'Gambar Saat Ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else if (showImagePicker)
              InkWell(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 150.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48.sp,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Tambah Gambar',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 16.h),

            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16.sp, color: Colors.blue[700]),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Gambar akan diunggah ke Supabase Storage saat menyimpan',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}