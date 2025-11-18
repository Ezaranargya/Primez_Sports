import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:iconsax/iconsax.dart';

class CategoryProductsPage extends StatelessWidget {
  final String category;
  final List<Product> products;
  final bool useGrid;

  const CategoryProductsPage({
    super.key,
    required this.category,
    required this.products,
    this.useGrid = true,
  });

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          category,
          style: TextStyle(
            fontFamily: "Poppins",
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: products.isEmpty
          ? _buildEmptyState()
          : useGrid
              ? _buildGridProductList()
              : _buildListProductList(),
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
            'Belum ada produk di kategori ini',
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

  Widget _buildGridProductList() {
    return GridView.builder(
      padding: EdgeInsets.all(12.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.70,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _CategoryProductCardGrid(product: product);
      },
    );
  }

  Widget _buildListProductList() {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: products.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return _CategoryProductCardList(product: products[index]);
      },
    );
  }
}

class _CategoryProductCardGrid extends StatelessWidget {
  final Product product;

  const _CategoryProductCardGrid({required this.product});

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
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(product.displayImage),
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.brand.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    )
                  ],
                  SizedBox(height: 6.h),
                  Text(
                    Formatter.formatPrice(product.price),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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

  Widget _buildProductImage(String image) {
    if (image.isEmpty) return _placeholder();

    Widget imageWidget;
    try {
      if (image.startsWith('data:image')) {
        final base64Data = image.split(',').last;
        final bytes = base64Decode(base64Data);
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } else if (image.startsWith('/9j/') || image.startsWith('iVBOR')) {
        final bytes = base64Decode(image);
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } else if (image.startsWith('http')) {
        imageWidget = Image.network(image,
            fit: BoxFit.contain, errorBuilder: (_, __, ___) => _placeholder());
      } else {
        imageWidget = Image.asset(image,
            fit: BoxFit.contain, errorBuilder: (_, __, ___) => _placeholder());
      }
    } catch (_) {
      imageWidget = _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      child: SizedBox(
        height: 128.h,
        width: double.infinity,
        child: imageWidget,
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 150.h,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
        ),
        child: Center(
          child: Icon(Icons.image_outlined, size: 40.sp, color: Colors.grey),
        ),
      );
}

class _CategoryProductCardList extends StatelessWidget {
  final Product product;

  const _CategoryProductCardList({required this.product});

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
        height: 120.h,
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.horizontal(left: Radius.circular(12.r)),
              child: SizedBox(
                width: 120.w,
                height: double.infinity,
                child: _buildProductImage(product.displayImage),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(product.name,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 8.h),
                    Text(Formatter.formatPrice(product.price),
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String image) {
    if (image.isEmpty) return _placeholder();

    try {
      if (image.startsWith('data:image')) {
        final base64Data = image.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, fit: BoxFit.contain);
      } else if (image.startsWith('/9j/') || image.startsWith('iVBOR')) {
        final bytes = base64Decode(image);
        return Image.memory(bytes, fit: BoxFit.contain);
      } else if (image.startsWith('http')) {
        return Image.network(image,
            fit: BoxFit.contain, errorBuilder: (_, __, ___) => _placeholder());
      } else {
        return Image.asset(image,
            fit: BoxFit.contain, errorBuilder: (_, __, ___) => _placeholder());
      }
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() => Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_outlined, size: 40.sp, color: Colors.grey),
        ),
      );
}