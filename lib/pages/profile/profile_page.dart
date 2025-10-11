import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/screens/login/login_page.dart';
import 'package:my_app/pages/profile/email_change_page.dart';
import 'package:my_app/theme/app_colors.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState () => _UserProfilePageState ();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String userEmail = "ezar@gmail.com";

  Future<void> _handleLogout() async {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE53E3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const Text(
          "Logout",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Apakah anda yakin ingin keluar?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Batal", style: TextStyle(color: Colors.white)),
            )
        ],
      ),
      );
  }

  void _handleEmailTap() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => EmailChangePage(currentEmail: userEmail)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 0.w,vertical: 0.h),
            padding: EdgeInsets.symmetric(vertical: 20.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE53E3E),
              borderRadius: BorderRadius.circular(0.r),
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
          Container(
            margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[350]!,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
                children: [
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline, size: 32.sp,color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      user?.displayName ?? "User",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ),
                    TextButton(
                      onPressed: () {}, 
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r)
                        ),
                      ),
                      child: Text("Edit", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      ),
                ],
            ),
          ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  _buildMenuItem(Icons.email_outlined, "Email", _handleEmailTap),
                  SizedBox(height: 12.h),
                  _buildMenuItem(Icons.favorite_outline, "Favorite", () {}),
                  SizedBox(height: 12.h),
                  _buildMenuItem(Icons.logout, "Logout", _handleLogout, isDestructive: true),
                ],
              ),
              )
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,{bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[350]!,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 24.sp, color: isDestructive ? AppColors.primary : Colors.black87),
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
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}