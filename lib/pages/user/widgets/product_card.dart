import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/providers/widgets/favorite_button.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool showFavoriteButton;
  final bool isHorizontal;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.isCompact = false,
    this.showFavoriteButton = true,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Card(
        child: ListTile(
          title: Text(product.name),
          trailing: showFavoriteButton
              ? FavoriteButton(
                  product: product,
                  size: 24,
                  activeColor: Colors.red,
                  inactiveColor: Colors.grey.shade400,
                )
              : null,
          onTap: onTap ?? () => _navigateToDetail(context),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap ?? () => _navigateToDetail(context),
      child: Container(
        width: 160.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                  child: _buildProductImage(product),
                ),
                if (showFavoriteButton)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: FavoriteButton(
                        product: product,
                        size: 20,
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatter.formatPrice(product.price),
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProductDetailPage(product: product),
      ),
    );
  }

  /// 🔹 GABUNG buildProductImage di sini
  Widget _buildProductImage(Product product, {double? width, double? height}) {
    final double imageHeight = height ?? 120;

    // Base64 image
    if (product.imageBase64 != null && product.imageBase64!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(product.imageBase64!),
          width: width ?? double.infinity,
          height: imageHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(imageHeight),
        );
      } catch (e) {
        print('❌ Error decoding base64: $e');
      }
    }

    // File local
    if (product.imageUrl.isNotEmpty) {
      if (product.imageUrl.startsWith('/data')) {
        return Image.file(
          File(product.imageUrl),
          width: width ?? double.infinity,
          height: imageHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(imageHeight),
        );
      } else if (product.imageUrl.startsWith('assets/')) {
        return Image.asset(
          product.imageUrl,
          width: width ?? double.infinity,
          height: imageHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(imageHeight),
        );
      } else {
        // Network image
        return Image.network(
          product.imageUrl,
          width: width ?? double.infinity,
          height: imageHeight,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: width ?? double.infinity,
              height: imageHeight,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _buildPlaceholder(imageHeight),
        );
      }
    }

    // Placeholder
    return _buildPlaceholder(imageHeight);
  }

  Widget _buildPlaceholder(double height) {
    return Container(
      width: double.infinity,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 40.sp, color: Colors.grey[400]),
          SizedBox(height: 4.h),
          Text('No Image', style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
