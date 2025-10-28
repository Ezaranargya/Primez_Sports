import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';

class NewSection extends StatelessWidget {
  final String title;
  final List<Product> products;

  const NewSection({
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 230.h, // ✅ Increased height
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (context, index) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final product = products[index];
                return _NewProductCard(product: product);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// ============================================================
/// 🔹 NEW PRODUCT CARD (Fixed overflow)
/// ============================================================
class _NewProductCard extends StatelessWidget {
  final Product product;

  const _NewProductCard({required this.product});

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
        width: 150.w, // ✅ Increased width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ Prevent overflow
          children: [
            // ✅ Product Image
            ProductImage(
                image: product.imageBase64?.isNotEmpty == true
                    ? product.imageBase64
                    : product.imageUrl ?? '',
                width: double.infinity,
                height: 130.h, // ✅ Fixed height
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),

            // ✅ Product Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Price
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