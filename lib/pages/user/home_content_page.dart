import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/user/widgets/banner_carousel.dart';
import 'package:my_app/pages/user/widgets/brand_section.dart';
import 'package:my_app/pages/user/widgets/home_header.dart';
import 'package:my_app/pages/user/widgets/new_section.dart';
import 'package:my_app/pages/user/widgets/trending_section.dart';

class HomeContentPage extends StatefulWidget {
  final List<Product> allProducts;

  const HomeContentPage({super.key, required this.allProducts});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  String searchQuery = "";
  String selectedCategory = "";

  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.allProducts
        .where((p) =>
            p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            p.brand.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    debugPrint('🔍 Total Products: ${filteredProducts.length}');

    final trendingProducts = filteredProducts
        .where((p) => p.categories.any((c) {
              final cat = c.toLowerCase();
              return cat.contains("trending") || cat.contains("trend");
            }))
        .toList();

    final newProducts = filteredProducts
        .where((p) => p.categories.any((c) {
              final cat = c.toLowerCase();
              return cat.contains("new") ||
                  cat.contains("terbaru") ||
                  cat.contains("baru");
            }))
        .toList();

    debugPrint('Trending Products: ${trendingProducts.length}');
    debugPrint('✨ New Products: ${newProducts.length}');

    for (var product in newProducts) {
      debugPrint('   - ${product.name}: ${product.categories}');
    }

    // ✅ Hindari error jika jumlah produk < 3
    final bannerData = filteredProducts.length >= 3
        ? filteredProducts.sublist(0, 3)
        : filteredProducts;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 110.h),
        child: HomeHeader(
          userName: "",
          searchQuery: searchQuery,
          selectedCategory: selectedCategory,
          onSearchChanged: (value) => setState(() => searchQuery = value),
          onCategorySelected: (category) =>
              setState(() => selectedCategory = category),
          allProducts: widget.allProducts,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ✅ Banner Carousel tetap utuh
            if (bannerData.isNotEmpty) BannerCarousel(banners: bannerData),
            const SizedBox(height: 20),
            if (trendingProducts.isNotEmpty)
              TrendingSection(title: "Trending", products: trendingProducts),
            const SizedBox(height: 20),
            if (newProducts.isNotEmpty)
              NewSection(title: "Terbaru", products: newProducts)
            else
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Tidak ada produk terbaru (${filteredProducts.length} total produk)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 20),
            if (filteredProducts.isNotEmpty)
              BrandSection(products: filteredProducts),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
