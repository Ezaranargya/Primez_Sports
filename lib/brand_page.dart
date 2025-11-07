import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:iconsax/iconsax.dart';

class BrandPage extends StatelessWidget {
  final String brandName;
  final String brandLogo;
  final List<Product> products;

  const BrandPage({
    super.key,
    required this.brandName,
    required this.brandLogo,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final brandProducts = products.where((product) {
      return product.brand.toLowerCase() == brandName.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53E3E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: brandLogo.isNotEmpty
                  ? Image.asset(
                      brandLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image, color: Colors.grey);
                      },
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: brandProducts.isEmpty
          ? _buildEmptyState()
          : _buildProductGrid(brandProducts),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            'Tidak ada produk untuk brand ini',
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> brandProducts) {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.65,
      ),
      itemCount: brandProducts.length,
      itemBuilder: (context, index) {
        final product = brandProducts[index];
        return _ProductCard(product: product);
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  Widget _buildImage() {
    final url = product.imageUrl;
    final base64Data = product.imageBase64 ?? '';

    if (base64Data.isNotEmpty) {
      try {
        final cleaned = base64Data.replaceFirst(
          RegExp(r'data:image/[^;]+;base64,'),
          '',
        );
        final bytes = base64Decode(cleaned);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  size: 40.sp,
                  color: Colors.grey,
                ),
              ),
            );
          },
        );
      } catch (_) {}
    }

    if (url.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_outlined, size: 40.sp, color: Colors.grey),
        ),
      );
    }

    if (url.startsWith('http')) {
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(Icons.broken_image, size: 40.sp, color: Colors.grey),
            ),
          );
        },
      );
    }

    if (!url.startsWith('/')) {
      return Image.asset(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 40.sp,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    }

    try {
      return Image.file(
        File(url),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 40.sp,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    } catch (_) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_outlined, size: 40.sp, color: Colors.grey),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                child: _buildImage(),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      Formatter.formatPrice(product.price),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
