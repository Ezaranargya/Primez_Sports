import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductImage extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (image.isEmpty) return _placeholder();

    if (image.startsWith('http://') || image.startsWith('https://')) {
      Widget imageWidget = CachedNetworkImage(
        imageUrl: image,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _loadingPlaceholder(),
        errorWidget: (context, url, error) => _placeholder(),
      );

      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius!,
          child: imageWidget,
        );
      }

      return imageWidget;
    }

    return _placeholder();
  }

  Widget _loadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 24.w,
          height: 24.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40.sp,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}