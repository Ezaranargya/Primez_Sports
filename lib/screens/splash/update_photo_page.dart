import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/user_photo_updater.dart';

class UpdatePhotoPage extends StatefulWidget {
  const UpdatePhotoPage({super.key});

  @override
  State<UpdatePhotoPage> createState() => _UpdatePhotoPageState();
}

class _UpdatePhotoPageState extends State<UpdatePhotoPage> {
  bool _isLoading = false;
  String? _currentPhotoUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentPhoto();
  }

  Future<void> _loadCurrentPhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _currentPhotoUrl = userDoc.data()?['photoUrl'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading photo: $e');
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      setState(() => _isLoading = true);

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Convert to base64
      final bytes = await File(image.path).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Update Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'photoUrl': base64Image,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update all existing posts
      await UserPhotoUpdater().updatePostsForUser(user.uid);

      if (mounted) {
        setState(() {
          _currentPhotoUrl = base64Image;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Foto profil berhasil diperbarui!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('❌ Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: const Text('Yakin ingin menghapus foto profil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Update user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'photoUrl': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update posts
      final updater = UserPhotoUpdater();
      await updater.updatePostsForUser(user.uid);

      if (mounted) {
        setState(() {
          _currentPhotoUrl = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto profil berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPhotoDisplay() {
    if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      try {
        final base64String = _currentPhotoUrl!.contains(',')
            ? _currentPhotoUrl!.split(',')[1]
            : _currentPhotoUrl!;
        final bytes = base64Decode(base64String);
        
        return CircleAvatar(
          radius: 80.r,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        debugPrint('Error decoding photo: $e');
      }
    }

    return CircleAvatar(
      radius: 80.r,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 80.sp,
        color: Colors.grey[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Update Foto Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Photo display
              Stack(
                children: [
                  _buildPhotoDisplay(),
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 32.h),

              // Info text
              Text(
                'Foto ini akan ditampilkan di profil Anda\ndan semua post komunitas',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13.sp,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32.h),

              // Upload button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickAndUploadPhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                        ? 'Ganti Foto'
                        : 'Pilih Foto',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              // Remove button (if photo exists)
              if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _removePhoto,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                      'Hapus Foto',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // Tips
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Tips: Gunakan foto dengan pencahayaan yang baik dan pastikan wajah terlihat jelas',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}