import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BannerWidget extends StatelessWidget {
  const BannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 140.h,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.pink.shade300],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            ),
        ),
        child: const Center(
          child: Icon(Icons.shopping_bag, color: Colors.white, size: 60),
        ),
      ),
    );
  }
}