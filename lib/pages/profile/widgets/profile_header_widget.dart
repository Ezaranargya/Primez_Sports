import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String? userImageUrl;
  final VoidCallback? onEditTap;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    this.userImageUrl,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            radius: 24.r,
            backgroundImage: userImageUrl != null && userImageUrl!.isNotEmpty
                ? NetworkImage(userImageUrl!)
                : null,
            child: (userImageUrl == null || userImageUrl!.isEmpty)
                ? Icon(
                    Icons.person_outline,
                    size: 22.sp,
                    color: Colors.grey[600],
                  )
                : null,
          ),

          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              userName,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onEditTap ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile clicked')),
                  );
                },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              minimumSize: Size(50.w, 28.h),
            ),
            child: Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
