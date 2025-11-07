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
            margin: EdgeInsets.all(12.w),
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
              child: product.imageUrl.isNotEmpty
                  ? (product.imageUrl.startsWith('assets/')
                      ? Image.asset(
                          product.imageUrl,
                          height: 180.h,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImageErrorPlaceholder();
                          },
                        )
                      : Image.network(
                          product.imageUrl,
                          height: 180.h,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 180.h,
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppColors.primary,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImageErrorPlaceholder();
                          },
                        ))
                  : _buildImageErrorPlaceholder(),
            ),
          ),
          if (product.description.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Deskripsi",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    product.description,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.6,
                      fontFamily: "Poppins",
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
          if (product.purchaseOptions.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Opsi Pembelian",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
            PurchaseOptionsList(options: product.purchaseOptions),
            SizedBox(height: 12.h),
          ],
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.sp,
                  color: Colors.blue.shade700,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Note: *Hanya admin yang bisa mengirim pesan',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontFamily: 'Poppins',
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      height: 180.h,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 60.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 8.h),
            Text(
              'Gambar tidak tersedia',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
