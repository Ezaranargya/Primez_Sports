import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';

class ProductInfoCard extends StatelessWidget {
  final String imagePath;
  final String description;

  const ProductInfoCard({
    super.key,
    required this.imagePath,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.asset(
                imagePath,
                height: 180.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180.h,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image,
                    size: 40.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            Text(
              description,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.5,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
