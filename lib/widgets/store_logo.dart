import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StoreLogo extends StatelessWidget {
  final String logoUrl;
  final double? size;
  final BoxFit fit;

  const StoreLogo({
    super.key,
    required this.logoUrl,
    this.size,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final double imageSize = size ?? 40.w;
    if (logoUrl.isEmpty) {
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.store,
          size: imageSize * 0.6,
          color: Colors.grey,
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Image.asset(
        logoUrl,
        width: imageSize,
        height: imageSize,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.image_not_supported,
              size: imageSize * 0.6,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }
}