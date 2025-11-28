import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/admin/product/product_detail_page.dart';
import 'package:my_app/theme/app_colors.dart';

class ProductItem extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const ProductItem({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  });

  String _formatPrice(num price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                  child: Image.asset(
                    product.imageUrl,
                    height: 120.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120.h,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40.sp,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
                if (showActions || onEdit != null || onDelete != null)
                  Positioned(
                    top: 4.h,
                    right: 4.w,
                    child: Row(
                      children: [
                        if (onEdit != null)
                          GestureDetector(
                            onTap: onEdit,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 14.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (onEdit != null && onDelete != null) SizedBox(width: 4.w),
                        if (onDelete != null)
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete,
                                size: 14.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rp${_formatPrice(product.price)}",
                      style: TextStyle(
                        color: AppColors.backgroundColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    if (product.brand.isNotEmpty)
                      Text(
                        product.brand,
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
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
