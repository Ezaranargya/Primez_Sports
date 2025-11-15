import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:my_app/pages/profile/edit_profile_page.dart';
import 'package:my_app/pages/profile/faq_page.dart';
import 'package:my_app/theme/app_colors.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoggingOut = false;

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
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 10),
              const Text("Logout"),
            ],
          ),
          content: const Text("Apakah Anda yakin ingin keluar?"),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)
                )
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)
                )
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Ya, Keluar"),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      // 1. Hapus token FCM dari Firestore
      await _deleteFCMToken();

      // 2. Lakukan Sign Out
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // 3. Navigasi menggunakan GoRouter.go() untuk memastikan stack navigasi bersih
      // Ini akan membawa user ke halaman login yang dikelola oleh GoRouter redirect.
      Future.microtask(() {
        if (mounted) {
          // Menggunakan context.go('/login') atau context.go('/')
          // agar GoRouter redirect di main.dart yang menangani
          // pengalihan ke /login/userhome bekerja dengan benar.
          context.go('/login'); 
        }
      });
      
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoggingOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saat logout: ${e.toString()}")),
      );
    }
  }

  void _handleEditProfile() async {
    // Menggunakan Navigator.push karena EditProfilePage mungkin bukan bagian dari GoRouter root
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );

    if (result == true && mounted) {
      // Memanggil setState agar StreamBuilder di atas me-refresh data user
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
    // Menggunakan Navigator.push karena FaqPage mungkin bukan bagian dari GoRouter root
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaqPage()),
    );
  }

  Widget _buildProfileImage(String? base64Image) {
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 2,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: (base64Image != null && base64Image.isNotEmpty)
            ? Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person_outline,
                      size: 32.sp, color: Colors.grey[600]);
                },
              )
            : Icon(Icons.person_outline,
                size: 32.sp, color: Colors.grey[600]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Menangani kasus di mana user tiba-tiba menjadi null (misalnya, sesi kedaluwarsa)
      return const Center(child: Text("Sesi pengguna tidak valid. Silakan login kembali."));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20.h,
                bottom: 20.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "Profile",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid) // Pastikan user tidak null di sini
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _loadingCard();
                      }

                      if (snapshot.hasError) {
                         debugPrint('Firebase Error: ${snapshot.error}');
                         return _errorCard("Gagal memuat data: ${snapshot.error.toString()}");
                      }

                      if (!snapshot.hasData || snapshot.data?.data() == null) {
                        return _emptyUserCard();
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final username =
                          userData['username'] ?? user.displayName ?? 'User';
                      final profile = userData['profile'] ?? '';
                      final photoBase64 = userData['photoBase64'];

                      return _profileCard(username, profile, photoBase64);
                    },
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        _buildMenuItem(Icons.help_outline, "FAQ", _handleFaqTap),
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

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Widget Helper ===== //

  Widget _loadingCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
  
  // Tambahkan error card untuk debugging
  Widget _errorCard(String message) {
     return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Text("Error: $message", style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _emptyUserCard() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Text("Data user tidak ditemukan. UID: ${user?.uid}"),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      boxShadow: [
        BoxShadow(
          color: Colors.grey[350]!,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _profileCard(String username, String profile, String? photoBase64) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _buildProfileImage(photoBase64),
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
                    style:
                        TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: _handleEditProfile,
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text(
              "Edit",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
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
      onTap: isLoading
          ? null
          : () {
              // Verifikasi ganda sebelum menjalankan onTap
              if (mounted && !_isLoggingOut) {
                onTap();
              }
            },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Icon(icon,
                size: 24.sp,
                color: isDestructive ? AppColors.primary : Colors.black87),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDestructive ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else
              Icon(Icons.arrow_forward_ios,
                  size: 16.sp, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}