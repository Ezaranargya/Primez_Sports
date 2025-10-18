import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/formatter.dart';

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
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (context, index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
                width: 1.2,
                color: Colors.grey.shade300,
              ),
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

class _NewProductCard extends StatelessWidget {
  final Product product;

  const _NewProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(product: product),
        ),
      ),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            const SizedBox(height: 6),
            _buildPrice(),
            const SizedBox(height: 2),
            _buildName(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final bool isNetworkImage = product.imagePath.startsWith('http');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: product.imagePath.isNotEmpty
          ? (isNetworkImage
              ? Image.network(
                  product.imagePath,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _placeholderImage(),
                )
              : Image.asset(
                  product.imagePath,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _placeholderImage(),
                ))
          : _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 110,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPrice() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        Formatter.formatPrice(product.price),
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildName() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 4.0),
      child: Text(
        product.name,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
