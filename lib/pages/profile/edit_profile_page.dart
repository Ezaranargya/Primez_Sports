import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/services/supabase_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _profileController = TextEditingController();
  final _bioController = TextEditingController();
  final _authService = AuthService();
  final _storageService = SupabaseStorageService();
  final picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _currentPhotoUrl;
  File? _newImageFile;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _profileController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _userId = user.uid;
          _usernameController.text = data['username'] ?? user.displayName ?? '';
          _profileController.text = data['profile'] ?? '';
          _bioController.text = data['bio'] ?? data['profile'] ?? '';
          _currentPhotoUrl = data['photoUrl'] ?? '';
          _isLoading = false;
        });
        
        debugPrint('✅ User data loaded');
        debugPrint('   Username: ${_usernameController.text}');
        debugPrint('   Photo URL: ${_currentPhotoUrl?.isNotEmpty == true ? "EXISTS" : "EMPTY"}');
      } else {
        setState(() {
          _usernameController.text = user.displayName ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('✅ Internet connected');
        return true;
      }
    } catch (e) {
      debugPrint('❌ No internet connection: $e');
      return false;
    }
    return false;
  }

  /// Pick image and save to permanent location
  Future<void> _pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      debugPrint('📸 Image picked from gallery: ${image.path}');

      // Langsung baca bytes dari XFile
      final bytes = await image.readAsBytes();
      debugPrint('📦 Read ${bytes.length} bytes from image');
      
      // Simpan ke app directory untuk menghindari file cache terhapus
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'temp_picked_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String permanentPath = path.join(appDir.path, fileName);
      
      final File permanentFile = File(permanentPath);
      await permanentFile.writeAsBytes(bytes);
      
      debugPrint('✅ Image saved to permanent location: $permanentPath');
      debugPrint('   File exists: ${await permanentFile.exists()}');

      setState(() {
        _newImageFile = permanentFile;
      });

      debugPrint('✅ Image selection complete');
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih gambar: $e'),
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

    if (confirmed == true) {
      setState(() {
        _newImageFile = null;
        _currentPhotoUrl = '';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // CEK INTERNET DULU jika ada foto yang akan di-upload
    if (_newImageFile != null) {
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❌ Tidak ada koneksi internet. Mohon cek WiFi/data seluler Anda.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      debugPrint('💾 Saving profile...');

      final newUsername = _usernameController.text.trim();
      
      await user.updateDisplayName(newUsername);

      String? finalPhotoUrl = _currentPhotoUrl;

      if (_newImageFile != null) {
        debugPrint('📤 Uploading new photo to Supabase...');
        
        // Hapus foto lama jika ada
        if (_currentPhotoUrl != null && 
            _currentPhotoUrl!.isNotEmpty && 
            _currentPhotoUrl!.startsWith('http')) {
          try {
            await _storageService.deleteImage(_currentPhotoUrl!);
            debugPrint('🗑️ Old photo deleted');
          } catch (e) {
            debugPrint('⚠️ Could not delete old photo: $e');
          }
        }

        // Upload foto baru
        finalPhotoUrl = await _storageService.uploadProfileImage(
          _newImageFile!,
          user.uid,
        );

        if (finalPhotoUrl == null) {
          throw Exception('Gagal upload foto ke Supabase Storage');
        }

        debugPrint('✅ Photo uploaded: $finalPhotoUrl');
      } else if (_currentPhotoUrl == '') {
        // User memilih untuk hapus foto
        if (_currentPhotoUrl != null && 
            _currentPhotoUrl!.isNotEmpty && 
            _currentPhotoUrl!.startsWith('http')) {
          try {
            await _storageService.deleteImage(_currentPhotoUrl!);
            debugPrint('🗑️ Photo deleted');
          } catch (e) {
            debugPrint('⚠️ Could not delete photo: $e');
          }
        }
        finalPhotoUrl = '';
      }

      // Update Firestore
      final updates = <String, dynamic>{
        'username': newUsername,
        'name': newUsername,
        'profile': _profileController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': finalPhotoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      debugPrint('📝 Updating Firestore...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));

      debugPrint('✅ Firestore updated');

      // Update username di posts
      if (newUsername.isNotEmpty) {
        try {
          await _authService.updateUsername(newUsername);
          debugPrint('✅ Username updated in posts');
        } catch (e) {
          debugPrint('⚠️ Could not update username in posts: $e');
        }
      }

      // Update photo URL di posts
      if (finalPhotoUrl != null && finalPhotoUrl.isNotEmpty) {
        try {
          await _authService.updatePhotoUrl(finalPhotoUrl, isBase64: false);
          debugPrint('✅ Photo URL updated in posts');
        } catch (e) {
          debugPrint('⚠️ Could not update photo in posts: $e');
        }
      } else if (finalPhotoUrl == '') {
        try {
          await _authService.removeProfilePhoto();
          debugPrint('✅ Photo removed from posts');
        } catch (e) {
          debugPrint('⚠️ Could not remove photo from posts: $e');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Profile berhasil diperbarui'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );

      Navigator.pop(context, true);
      
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileImage() {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
        border: Border.all(
          color: const Color(0xFFFFFFFF),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 2,
            spreadRadius: 2,
          )
        ]
      ),
      child: ClipOval(
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_newImageFile != null) {
      return Image.file(
        _newImageFile!,
        fit: BoxFit.cover,
      );
    }

    if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      if (_currentPhotoUrl!.startsWith('http')) {
        return Image.network(
          _currentPhotoUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Error loading photo: $error');
            return _buildPlaceholder();
          },
        );
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Icon(
      Icons.person,
      size: 60.sp,
      color: Colors.grey[400],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20.h),
                
                Stack(
                  children: [
                    _buildProfileImage(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53E3E),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 18.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          if (_currentPhotoUrl?.isNotEmpty == true || 
                              _newImageFile != null) ...[
                            SizedBox(width: 8.w),
                            InkWell(
                              onTap: _removePhoto,
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40.h),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Username',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _usernameController,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your username',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14.sp,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53E3E),
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username tidak boleh kosong';
                        }
                        if (value.trim().length < 3) {
                          return 'Username minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                SizedBox(height: 24.h),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 5,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Silahkan menaruh bio anda disini',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14.sp,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53E3E),
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40.h),
                
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isSaving) ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53E3E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: (_isLoading || _isSaving)
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}