import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/pages/product/product_detail_page.dart';


class FavoriteItemCard extends StatelessWidget {
  final Product? product;

  const FavoriteItemCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return Center(
        child: SizedBox(
          width: 340.w,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Data produk tidak tersedia',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: 340.w,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProductDetailPage(product: product!),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: (product!.imageUrl.isNotEmpty)
                        ? Image.network(
                            product!.imageUrl,
                            width: 80.w,
                            height: 80.h,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80.w,
                                height: 80.h,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 32.sp,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 80.w,
                            height: 80.h,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 32.sp,
                              color: Colors.grey,
                            ),
                          ),
                  ),

                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product!.name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        if (product!.brand.isNotEmpty)
                          Text(
                            product!.brand,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontFamily: 'Poppins',
                              color: Colors.grey[600],
                            ),
                          ),
                        SizedBox(height: 6.h),
                        Text(
                          Formatter.formatPrice(product!.price),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 15.sp,
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
          ),
        ),
      ),
    );
  }
}
