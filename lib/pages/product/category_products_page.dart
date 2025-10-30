import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/formatter.dart';

class CategoryProductsPage extends StatelessWidget {
  final String category;
  final List<Product> products;
  final bool useGrid; // ⚡ Tambahan flag untuk memilih layout grid atau list

  const CategoryProductsPage({
    super.key,
    required this.category,
    required this.products,
    this.useGrid = true, // default grid
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
          icon: const Icon(Icons.chevron_left, size: 32),
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
        childAspectRatio: 0.72,
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

/// 🔹 Card versi Grid
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
            _buildProductImage(),
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
                  SizedBox(height: 6.h),
                  Text(
                    Formatter.formatPrice(product.price),
                    style: TextStyle(
                      fontSize: 14.sp,
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

  Widget _buildProductImage() {
    if (product.imageUrl.isEmpty) return _placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      child: product.imageUrl.startsWith('http')
          ? Image.network(
              product.imageUrl,
              height: 120.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            )
          : Image.asset(
              product.imageUrl,
              height: 120.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 120.h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40.sp,
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// 🔹 Card versi List (Horizontal)
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
              child: _buildProductImage(),
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

  Widget _buildProductImage() {
    if (product.imageUrl.isEmpty) return _placeholder();

    return product.imageUrl.startsWith('http')
        ? Image.network(product.imageUrl,
            width: 120.w,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder())
        : Image.asset(product.imageUrl,
            width: 120.w,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder());
  }

  Widget _placeholder() => Container(
        width: 120.w,
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_outlined, size: 40.sp, color: Colors.grey),
        ),
      );
}
