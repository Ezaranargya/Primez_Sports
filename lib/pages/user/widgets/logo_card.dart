import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget logoCard(String imagePath, String brandName, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 80.w,
      height: 90.h,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: imagePath.startsWith("http")
            ? Image.network(
                imagePath,
                fit: BoxFit.contain,
              )
            : Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
              ),
              SizedBox(height: 6.h),
              Text(
                brandName,
                style: TextStyle(fontSize: 12.sp,fontWeight: FontWeight.bold,color: Colors.black87),
              ),
          ],
        ),
      ),
    ),
  );
}
