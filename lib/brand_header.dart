import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BrandHeader extends StatelessWidget {
  final String brandName;
  final String logoPath;
  final VoidCallback onBack;

  const BrandHeader({
    super.key,
    required this.brandName,
    required this.logoPath,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: onBack,
          ),

          
          Image.asset(
            logoPath,
            width: 26.w,
            height: 26.w,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 10.w),

          
          Expanded(
            child: Text(
              "Kumpulan Brand $brandName Official",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
