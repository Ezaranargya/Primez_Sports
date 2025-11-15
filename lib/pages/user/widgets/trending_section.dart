import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';

class TrendingSection extends StatelessWidget {
  final String title;
  final List<Product> products;

  const TrendingSection({
    super.key,
    required this.title,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(products.length, (index) {
                final product = products[index];
                return Row(
                  children: [
                    _TrendingProductCard(product: product),

                    if (index != products.length - 1)
                      Container(
                        height: 120.h,
                        width: 1.2.w,
                        margin: EdgeInsets.symmetric(horizontal: 10.w),
                        color: Colors.grey.shade300,
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendingProductCard extends StatelessWidget {
  final Product product;

  const _TrendingProductCard({required this.product});

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
        width: 115.w, 
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: ProductImage(
                image: product.imageBase64?.isNotEmpty == true
                    ? product.imageBase64
                    : product.imageUrl ?? '',
                width: double.infinity,
                height: 100.h, 
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),

            ),
            SizedBox(height: 6.h),

            
            Text(
              Formatter.formatPrice(product.price),
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),

            
            Text(
              product.name,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontFamily: 'Poppins',
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
