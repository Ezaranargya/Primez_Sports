import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommunityFooter extends StatelessWidget {
  const CommunityFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Text(
        "*Ayo ikuti salah satu komunitas ini agar mudah untuk mendapatkan informasi terbaru mengenai sepatu olahraga terkini.",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.black54,
          height: 1.4,
        ),
      ),
    );
  }
}
