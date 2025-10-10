import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/user/widgets/product_card.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:my_app/pages/product/product_detail_page.dart';

class TrendingSection extends StatelessWidget{
  final String title;
  final List<Product> produtcs;

  const TrendingSection({
    super.key,
    required this.title,
    required this.produtcs,
  });

  @override 
  Widget build(BuildContext context) {
    if (produtcs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: TextStyle(fontFamily: 'Poppins',fontSize: 20,fontWeight: FontWeight.bold,color: Colors.black87),
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
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: produtcs.length,
              separatorBuilder: (context, index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
                width: 1.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                ),
              ),
              itemBuilder: (context, index) {
                final product = produtcs[index];
                return _productCard(product: product);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _productCard extends StatelessWidget {
  final Product product;

  const _productCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
      ),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageWithBadge(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                Formatter.currency(product.price),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithBadge() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: product.imageUrl.isNotEmpty
          ? Image.network(
              product.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            )
          : Container(
              height: 120,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
            ),
    );
  }
}