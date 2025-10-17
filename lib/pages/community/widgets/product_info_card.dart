import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/pages/product/purchase_options_list.dart';

class ProductInfoCard extends StatelessWidget {
  final Product product;

  const ProductInfoCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: product.imagePath.isNotEmpty
                  ? (product.imagePath.startsWith('assets/')
                      ? Image.asset(
                          product.imagePath,
                          height: 180.h,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImageErrorPlaceholder();
                          },
                        )
                      : Image.network(
                          product.imagePath,
                          height: 180.h,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImageErrorPlaceholder();
                          },
                        ))
                  : _buildImageErrorPlaceholder(),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12.w),
            child: Text(
              product.description,
              style: TextStyle(
                fontSize: 12.sp,
                fontFamily: 'Poppins',
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),

          if (product.purchaseOptions.isNotEmpty)
            PurchaseOptionsList(options: product.purchaseOptions),

          Container(
            padding: EdgeInsets.all(12.w),
            child: Text(
              'Note: *Hanya admin yang bisa mengirim pesan',
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: 'Poppins',
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      height: 180.h,
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 60.sp,
          color: Colors.grey,
        ),
      ),
    );
  }
}
