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
  final allProducts = widget.allProducts;

  // Debug
  debugPrint('🔍 Total Products: ${allProducts.length}');
  
  // Filter produk trending
  final trendingProducts = allProducts
      .where((p) => p.categories.any((c) {
        final cat = c.toLowerCase();
        return cat.contains("trending") || cat.contains("trend");
      }))
      .toList();
  
  // Filter produk new/terbaru - LEBIH FLEKSIBEL
  final newProducts = allProducts
      .where((p) => p.categories.any((c) {
        final cat = c.toLowerCase();
        return cat.contains("new") || 
               cat.contains("terbaru") || 
               cat.contains("baru");
      }))
      .toList();

  // Debug hasil filter
  debugPrint('🔥 Trending Products: ${trendingProducts.length}');
  debugPrint('✨ New Products: ${newProducts.length}');
  
  for (var product in newProducts) {
    debugPrint('   - ${product.name}: ${product.categories}');
  }

  // Banner
  final bannerData = [
    {
      'image': 'assets/Nike_Giannis_Immortality_4_1.png',
      'product': allProducts.length > 2 ? allProducts[2] : null,
    },
    {
      'image':
          'assets/Sepak_Bola_PUMA_x_NEYMAR_JR_FUTURE_7_ULTIMATE_FGAG_1.png',
      'product': allProducts.length > 1 ? allProducts[1] : null,
    },
    {
      'image': 'assets/Mizuno_Wave_Momentum_3_1.png',
      'product': allProducts.isNotEmpty ? allProducts[0] : null,
    },
  ];

  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight + 110),
      child: HomeHeader(
        userName: "",
        searchQuery: searchQuery,
        selectedCategory: selectedCategory,
        onSearchChanged: (value) => setState(() => searchQuery = value),
        onCategorySelected: (category) =>
            setState(() => selectedCategory = category),
        allProducts: allProducts,
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          BannerCarousel(banners: bannerData),
          const SizedBox(height: 20),
          if (trendingProducts.isNotEmpty)
            TrendingSection(title: "Trending", products: trendingProducts),
          const SizedBox(height: 20),
          if (newProducts.isNotEmpty)
            NewSection(title: "Terbaru", products: newProducts)
          else
            // Debug jika tidak ada produk baru
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tidak ada produk terbaru (${allProducts.length} total produk)',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 20),
          BrandSection(products: allProducts),
          const SizedBox(height: 80),
        ],
      ),
    ),
  );
}
}