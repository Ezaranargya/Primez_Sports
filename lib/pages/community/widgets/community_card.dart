import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommunityCard extends StatelessWidget {
  final String title;
  final String brand;
  final VoidCallback onTap;

  const CommunityCard({
    super.key,
    required this.title,
    required this.brand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Peta brand ke logo
    final Map<String, String> brandLogos = {
      "Nike": "assets/logo_nike.png",
      "Jordan": "assets/logo_jordan.png",
      "Adidas": "assets/logo_adidas.png",
      "Under Armour": "assets/logo_under_armour.png",
      "Puma": "assets/logo_puma.png",
      "Mizuno": "assets/logo_mizuno.png",
    };

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        leading: CircleAvatar(
          radius: 20.r,
          backgroundColor: Colors.grey[200],
          child: brandLogos.containsKey(brand)
              ? Padding(
                padding: EdgeInsets.all(6.w),
                child: Image.asset(
                  brandLogos[brand]!,
                  fit: BoxFit.contain,
                  width: 24.w,
                  height: 24.w,
                ),
                )
              : Text(
                  brand[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
