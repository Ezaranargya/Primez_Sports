import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';

/// =============================================================
/// 🧩 Widget: CommunityHeader (AppBar merah + card putih)
/// =============================================================
class CommunityHeader extends StatelessWidget {
  final String brandName;
  final String logoPath;
  final VoidCallback onBack;

  const CommunityHeader({
    super.key,
    required this.brandName,
    required this.logoPath,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🔴 Background merah bagian atas
          Container(
            height: 73.h,
            width: double.infinity,
            color: AppColors.primary,
            child: SafeArea(
              child: Center(
                child: Text(
                  "Chat Komunitas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          // ⚪ Card putih di bawah merah
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom: -25,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔙 Tombol kembali
                  GestureDetector(
                    onTap: onBack,
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black87,
                      size: 20.sp,
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // 🖼️ Logo brand
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.asset(
                        logoPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          size: 24.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // 📝 Nama komunitas
                  Expanded(
                    child: Text(
                      "Kumpulan Brand Sepatu $brandName Official",
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
