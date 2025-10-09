import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/pages/user/widgets/product_card.dart';
import 'package:my_app/theme/app_colors.dart';


class ProductSection extends StatelessWidget {
  final String title;
  final List<Product> products;
  final bool isWide;

  const ProductSection({
    super.key,
    required this.title,
    required this.products,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 12.h),
        _buildContent(),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (products.length > 2)
          TextButton(
            onPressed: () {
            },
            child: Text(
              "Lihat Semua",
              style: TextStyle(
                color: const Color(0xFFE53E3E),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (isWide) {
      return _buildGridView();
    }
    return _buildHorizontalList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              "Produk tidak ditemukan",
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 2 / 3,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () => _navigateToDetail(context, product),
          child: ProductCard(
            product: product,
            isHorizontal: false,
          ),
        );
      },
    );
  }

  Widget _buildHorizontalList() {
    return SizedBox(
      height: 230.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 140.w,
            child: GestureDetector(
              onTap: () => _navigateToDetail(context, product),
              child: ProductCard(
                product: product,
                isHorizontal: false,
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product),
      ),
    );
  }
}
