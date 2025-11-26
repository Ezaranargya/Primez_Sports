import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isHorizontal;
  final double? width;
  final double? imageHeight;

  const ProductCard({
    super.key,
    required this.product,
    this.isHorizontal = false,
    this.width,
    this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    
    final cardWidth = width ?? (isHorizontal ? 180.w : 150.w);
    final imgHeight = imageHeight ?? (isHorizontal ? 140.h : 120.h);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProductDetailPage(product: product),
        ),
      ),
      child: Container(
        width: cardWidth,
        margin: isHorizontal 
            ? EdgeInsets.only(right: 12.w) 
            : EdgeInsets.zero,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            ProductImage(
              image: product.imageUrl ?? '',
              width: double.infinity,
              height: 130.h, 
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),

            
            Padding(
              padding: EdgeInsets.all(isHorizontal ? 12.w : 8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Text(
                    Formatter.formatPrice(product.price),
                    style: TextStyle(
                      fontSize: isHorizontal ? 16.sp : 14.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: isHorizontal ? 14.sp : 13.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
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
}




class CompactProductCard extends StatelessWidget {
  final Product product;

  const CompactProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProductDetailPage(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Expanded(
              flex: 6,
              child: ProductImage(
                image: product.imageUrl ?? '',
                width: double.infinity,
                height: 130.h, 
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),

            
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Formatter.formatPrice(product.price),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class LargeProductCard extends StatelessWidget {
  final Product product;

  const LargeProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProductDetailPage(product: product),
        ),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            ProductImage(
              image: product.imageUrl ?? '',
              width: double.infinity,
              height: 200.h, 
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),

            
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brand.isNotEmpty) ...[
                    Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4.h),
                  ],
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    Formatter.formatPrice(product.price),
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}