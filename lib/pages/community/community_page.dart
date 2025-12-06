import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/pages/community/community_chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserCommunityPage extends StatefulWidget {
  const UserCommunityPage({super.key});

  @override
  State<UserCommunityPage> createState() => _UserCommunityPageState();
}

class _UserCommunityPageState extends State<UserCommunityPage> {
  final List<String> _allBrands = [
    'Nike',
    'Jordan',
    'Adidas',
    'Under Armour',
    'Puma',
    'Mizuno',
  ];

  final Map<String, String> _brandLogos = {
    'Nike': 'assets/logo_nike.png',
    'Jordan': 'assets/logo_jordan.png',
    'Adidas': 'assets/logo_adidas.png',
    'Under Armour': 'assets/logo_under_armour.png',
    'Puma': 'assets/logo_puma.png',
    'Mizuno': 'assets/logo_mizuno.png',
  };

  // Stream untuk menghitung jumlah post per brand
  Stream<Map<String, int>> _getPostCountsStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .snapshots()
        .map((snapshot) {
      final Map<String, int> counts = {};
      
      for (var brand in _allBrands) {
        counts[brand] = 0;
      }
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final brand = data['brand']?.toString() ?? '';
        
        if (counts.containsKey(brand)) {
          counts[brand] = (counts[brand] ?? 0) + 1;
        }
      }
      
      return counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Chat Komunitas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, int>>(
        stream: _getPostCountsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    '❌ Terjadi kesalahan',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final postCounts = snapshot.data ?? {};

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _allBrands.length,
            itemBuilder: (context, index) {
              final brand = _allBrands[index];
              final postCount = postCounts[brand] ?? 0;
              return _buildBrandCard(brand, postCount);
            },
          );
        },
      ),
    );
  }

  Widget _buildBrandCard(String brand, int postCount) {
    final logo = _brandLogos[brand] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserCommunityChatPage(brand: brand),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Logo Brand
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: logo.isNotEmpty
                      ? Padding(
                          padding: EdgeInsets.all(10.w),
                          child: Image.asset(
                            logo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.store,
                              size: 24.sp,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Icon(Icons.store, size: 24.sp, color: Colors.grey),
                ),
                SizedBox(width: 16.w),

                // Info Brand
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kumpulan Sepatu Brand $brand Official',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        postCount > 0
                            ? '$postCount post tersedia'
                            : 'Belum ada post',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: postCount > 0
                              ? Colors.green[600]
                              : Colors.grey[500],
                          fontWeight: postCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),

                // Badge Messenger
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}