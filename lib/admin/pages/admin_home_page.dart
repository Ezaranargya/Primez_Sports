import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/admin/product/product_page.dart';
import 'package:my_app/admin/community/community_page.dart';
import 'package:my_app/admin/news/news_page.dart';
import 'package:my_app/admin/profile_page.dart'; 
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/admin/product/admin_product_add_page.dart';
import 'package:my_app/admin/product/product_detail_page.dart';
import 'package:my_app/admin/product/edit_product_screen.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text(
              'Admin',
              style: TextStyle(color: AppColors.backgroundColor),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AdminCard(
                      icon: Icons.inventory_2_rounded,
                      label: 'Product',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminProductPage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 24.w),
                    _AdminCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Komunitas',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminCommunityPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AdminCard(
                      icon: Icons.article_outlined,
                      label: 'News',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminNewsPage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 24.w),
                    _AdminCard(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminProfilePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        width: 120.w,
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.sp, color: Colors.black87),
            SizedBox(height: 10.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
