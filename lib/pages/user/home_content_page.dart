import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/brand_page.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/pages/user/widgets/brand_section.dart';
import 'package:my_app/pages/user/widgets/home_header.dart';
import 'package:my_app/pages/user/widgets/new_section.dart';
import 'package:my_app/pages/user/widgets/trending_section.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/pages/product/category_products_page.dart';
import 'package:my_app/models/purchase_option.dart';

class BannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final double height;
  final double borderRadius;
  final Color activeColor;
  final bool autoPlay;
  final Duration autoPlayInterval;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.height = 160,
    this.borderRadius = 12,
    this.activeColor = Colors.redAccent,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      Future.delayed(widget.autoPlayInterval, _autoSlide);
    }
  }

  void _autoSlide() {
    if (!mounted) return;
    final nextPage = (_currentPage + 1) % widget.banners.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    if (widget.autoPlay) {
      Future.delayed(widget.autoPlayInterval, _autoSlide);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius.r),
                  child: GestureDetector(
                    onTap: () {
                      if (banner['product'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProductDetailPage(product: banner['product']),
                          ),
                        );
                      }
                    },
                    child: Image.asset(
                      banner['image'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            bool isActive = index == _currentPage;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              height: 10.w,
              width: 10.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? widget.activeColor : Colors.transparent,
                border: Border.all(color: widget.activeColor, width: 1.5),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// 🔹 Stream real-time ambil produk dari root collection `products`
Stream<List<Product>> fetchProductsStream() {
  return FirebaseFirestore.instance
      .collection('products')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
}

class HomeContentPage extends StatefulWidget {
  final List<Product> allProducts;
  const HomeContentPage({super.key, this.allProducts = const []});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  String searchQuery = "";
  String selectedCategory = "";

  final List<Map<String, String>> categories = [
    {"display": "Basketball shoes", "filter": "basketball"},
    {"display": "Soccer shoes", "filter": "soccer"},
    {"display": "Volleyball shoes", "filter": "volleyball"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: HomeHeader(
          userName: "",
          searchQuery: searchQuery,
          selectedCategory: selectedCategory,
          categories: categories,
          onSearchChanged: (value) => setState(() => searchQuery = value),
          onCategorySelected: (category) {
            // Navigasi ke halaman produk berdasarkan kategori
          },
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: fetchProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan saat memuat produk'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada produk'));
          }

          final products = snapshot.data!;
          final trendingProducts = products.where((p) {
            return p.categories.any((c) =>
                c.toLowerCase().contains("trending") ||
                c.toLowerCase().contains("popular") ||
                c.toLowerCase().contains("populer"));
          }).toList();

          final newProducts = products.where((p) {
            return p.categories.any((c) =>
                c.toLowerCase().contains("new") ||
                c.toLowerCase().contains("baru") ||
                c.toLowerCase().contains("terbaru"));
          }).toList();

          final bannerData = [
            {
              'image': 'assets/Nike_Giannis_Immortality_4_1.png',
              'product': products.length > 2 ? products[2] : null,
            },
            {
              'image': 'assets/Sepak_Bola_PUMA_x_NEYMAR_JR_FUTURE_7_ULTIMATE_FGAG_1.png',
              'product': products.length > 1 ? products[1] : null,
            },
            {
              'image': 'assets/Mizuno_Wave_Momentum_3_1.png',
              'product': products.isNotEmpty ? products[0] : null,
            },
          ];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                BannerCarousel(banners: bannerData),
                const SizedBox(height: 20),
                if (trendingProducts.isNotEmpty)
                  TrendingSection(title: "Trending", products: trendingProducts)
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('⚠️ No trending products found'),
                  ),
                const SizedBox(height: 20),
                if (newProducts.isNotEmpty)
                  NewSection(title: "Terbaru", products: newProducts)
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                  ),
                BrandSection(products: products),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}
