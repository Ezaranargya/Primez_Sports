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
  final bool isHorizontal;
  final bool showFavoriteButton;
  final bool isCompact; 

  const ProductCard({
    super.key,
    required this.product,
    this.isHorizontal = false,
    this.onTap,
    this.showFavoriteButton = true,
    this.isCompact = false,
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
          onTap: onTap ??
              () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(product: product),
                    ),
                  ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(product: product),
                ),
              ),
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
                  child: Image(
                    image: product.imagePath.startsWith('http')
                        ? NetworkImage(product.imagePath)
                        : AssetImage(product.imagePath) as ImageProvider,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Error load gambar: $error');
                      return Container(
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
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
}

class ProductHorizontalList extends StatelessWidget {
  final String title;
  final List<Product> products;
  final VoidCallback? onSeeAll;
  final int maxItems;
  final bool showFavoriteButton;

  const ProductHorizontalList({
    super.key,
    required this.title,
    required this.products,
    this.onSeeAll,
    this.maxItems = 2,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayProducts = products.length > maxItems
        ? products.sublist(0, maxItems)
        : products;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (products.length > maxItems || onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    "Lihat Semua",
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        Padding(
          padding: EdgeInsets.only(left: 16.w, top: 4.h),
          child: Container(
            height: 2.h,
            width: 60.w,
            color: AppColors.primary,
          ),
        ),

        SizedBox(height: 12.h),

        SizedBox(
          height: 240.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: displayProducts.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              return ProductCard(
                product: displayProducts[index],
                showFavoriteButton: showFavoriteButton,
              );
            },
          ),
        ),
      ],
    );
  }
}