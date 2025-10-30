import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String brandName;
  final String brandLogo;
  final VoidCallback onBack;
  final VoidCallback onFollow;

  const BrandAppBar({
    super.key,
    required this.brandName,
    required this.brandLogo,
    required this.onBack,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            
            IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_ios_new, size: 18.sp),
              color: Colors.black87,
            ),

            
            CircleAvatar(
              radius: 16.r,
              backgroundColor: Colors.grey[200],
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Image.asset(
                  brandLogo,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            SizedBox(width: 10.w),

            
            Expanded(
              child: Text(
                "Kumpulan Brand $brandName Official",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            
            GestureDetector(
              onTap: onFollow,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  "Ikuti",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60.h);
}
