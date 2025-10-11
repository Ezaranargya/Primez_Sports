import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';

class CommunityHeader extends StatelessWidget {
  final String title;

  const CommunityHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
      child: Container(
        width: double.infinity,
        height: 60.h,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(0.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 3),
              blurRadius: 5,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
