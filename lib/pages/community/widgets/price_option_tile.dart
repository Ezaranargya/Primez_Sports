import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';

class PriceOptionTile extends StatelessWidget {
  final String price;
  final String seller;
  final VoidCallback? onTap;

  const PriceOptionTile({
    super.key,
    required this.price,
    required this.seller,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(1.r),
          border: Border.all(color: Colors.black, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: AppColors.backgroundColor,
              ),
            ),

            const Spacer(),

            Text(
              seller,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black,
              ),
            ),

            SizedBox(width: 6.w),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.sp,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
