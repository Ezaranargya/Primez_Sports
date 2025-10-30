import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';








class LogoCard extends StatelessWidget {
  final String imageUrl;
  final String brandName;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const LogoCard({
    super.key,
    required this.imageUrl,
    required this.brandName,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 100.w,
        height: height ?? 100.h,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.network(
                imageUrl,
                width: 60.w,
                height: 60.h,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60.w,
                    height: 60.h,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 30.sp,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 60.w,
                    height: 60.h,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8.h),
            
            
            Text(
              brandName,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}






Widget logoCard(String imageUrl, String brandName, VoidCallback onTap) {
  return LogoCard(
    imageUrl: imageUrl,
    brandName: brandName,
    onTap: onTap,
  );
}




class CompactLogoCard extends StatelessWidget {
  final String imageUrl;
  final String brandName;
  final VoidCallback onTap;

  const CompactLogoCard({
    super.key,
    required this.imageUrl,
    required this.brandName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80.w,
        height: 80.h,
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: 24.sp,
            );
          },
        ),
      ),
    );
  }
}




class CircleLogoCard extends StatelessWidget {
  final String imageUrl;
  final String brandName;
  final VoidCallback onTap;
  final double size;

  const CircleLogoCard({
    super.key,
    required this.imageUrl,
    required this.brandName,
    required this.onTap,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size.w,
            height: size.h,
            margin: EdgeInsets.only(right: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(12.w),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[400],
                  size: (size * 0.4).sp,
                );
              },
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: size.w,
            child: Text(
              brandName,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}