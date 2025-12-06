import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/pages/profile/edit_profile_page.dart';
import 'package:my_app/pages/profile/faq_page.dart';
import 'package:my_app/services/supabase_migration_service.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/widgets/user_avatar.dart';

class UserProfilePage extends StatefulWidget {
  final String? userId; 

  const UserProfilePage({super.key, this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoggingOut = false;
  bool _isMigrating = false;

  String get _currentUserId {
    return widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  bool get _isOwnProfile {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && widget.userId == null;
  }

  Future<void> _migrateToSupabase() async {
    if (_isMigrating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrasi ke Supabase Storage'),
        content: const Text(
          'Proses ini akan memindahkan semua gambar dari base64 ke Supabase Storage.\n\n'
          'Proses memakan waktu beberapa menit tergantung jumlah data.\n\n'
          'Proses ini hanya perlu dilakukan SEKALI SAJA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Mulai Migrasi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isMigrating = true);

    try {
      debugPrint('🚀 Starting migration to Supabase...');
      
      final migrationService = SupabaseMigrationService();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Migrasi sedang berjalan...'),
                const SizedBox(height: 8),
                Text(
                  'Mohon jangan tutup aplikasi',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await migrationService.runFullMigration();

      if (!mounted) return;
      
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Migrasi berhasil! Semua gambar sudah di Supabase Storage'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      setState(() {});

    } catch (e) {
      debugPrint('❌ Error migration: $e');

      if (!mounted) return;
      
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error migrasi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  Future<void> _deleteFCMToken() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': FieldValue.delete(),
        });
        debugPrint('✅ FCM Token successfully deleted from Firestore.');
      } catch (e) {
        debugPrint('❌ Error deleting FCM token: $e');
      }
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24.sp),
              SizedBox(width: 10.w),
              Text(
                "Logout",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            "Apakah Anda yakin ingin keluar?",
            style: TextStyle(fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                "Batal",
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                "Ya, Keluar",
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      await _deleteFCMToken();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Future.microtask(() {
        if (mounted) {
          context.go('/login'); 
        }
      });
      
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoggingOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saat logout: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );

    if (result == true && mounted) {
      setState(() {}); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile berhasil diperbarui'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleFaqTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaqPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOwnProfile && _currentUserId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("Profile"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  "User tidak ditemukan",
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Profile yang Anda cari tidak tersedia",
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isOwnProfile ? "Profile" : "Profile"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUserId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _loadingCard();
                      }

                      if (snapshot.hasError) {
                        debugPrint('Firebase Error: ${snapshot.error}');
                        return _errorCard("Gagal memuat data: ${snapshot.error.toString()}");
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return _emptyUserCard();
                      }

                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                      final username = userData['username'] ?? 'User';
                      final profile = userData['profile'] ?? '';
                      final photoUrl = userData['photoUrl'] ?? '';
                      final bio = userData['bio'] ?? '';

                      return _profileCard(
                        userId: _currentUserId,
                        username: username,
                        profile: profile,
                        photoUrl: photoUrl,
                        bio: bio,
                        isOwnProfile: _isOwnProfile,
                      );
                    },
                  ),

                  if (_isOwnProfile) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        children: [
                          SizedBox(height: 12.h),
                          
                          _buildMenuItem(
                            Icons.help_outline,
                            "FAQ",
                            _handleFaqTap,
                          ),
                          SizedBox(height: 12.h),
                          
                          _buildMenuItem(
                            Icons.logout,
                            "Logout",
                            _isLoggingOut ? () {} : _handleLogout,
                            isDestructive: true,
                            isLoading: _isLoggingOut,
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              "Memuat data profile...",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _errorCard(String message) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            "Gagal memuat profile",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyUserCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.person_off, size: 48.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            "User tidak ditemukan",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            "Data profile tidak tersedia",
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _profileCard({
    required String userId,
    required String username,
    required String profile,
    required String photoUrl,
    required String bio,
    required bool isOwnProfile,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          UserAvatar(
            photoUrl: photoUrl,
            userId: userId,
            username: username,
            bio: bio,
            size: 60,
          ),
          
          SizedBox(width: 16.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (profile.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    profile,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    bio,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          if (isOwnProfile)
            TextButton(
              onPressed: _handleEditProfile,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                "Edit",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isDestructive ? Colors.red : AppColors.primary,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : Colors.black87,
                ),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDestructive ? Colors.red : AppColors.primary,
                  ),
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}