import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'package:my_app/pages/user/widgets/product_card.dart';
import 'package:my_app/pages/product/product_detail_page.dart';

class BrandPage extends StatelessWidget {
  final String brandName;
  final List<Product> products;
  final String? brandLogo;

  const BrandPage({
    super.key,
    required this.brandName,
    required this.products,
    this.brandLogo,
  });

  @override
  Widget build(BuildContext context) {
    final brandProducts = products.where((product) {
      final name = product.name.toLowerCase();
      return name.contains(brandName.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53E3E),
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            size: 32,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (brandLogo != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: brandLogo!.startsWith('http')
                    ? Image.network(
                        brandLogo!,
                        height: 28,
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        brandLogo!,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
              ),
            Flexible(
              child: Text(
                brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: brandProducts.isEmpty
          ? const Center(
              child: Text(
                "Tidak ada produk",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 18,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: brandProducts.map((product) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailPage(product: product),
                            ),
                          );
                        },
                        child: ProductCard(
                          product: product,
                          isHorizontal: true,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
