import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/news/widgets/news_header.dart';
import 'package:my_app/pages/news/widgets/news_product_card.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:intl/intl.dart';

class UserNewsPage extends StatefulWidget {
  const UserNewsPage({super.key});

  @override
  State<UserNewsPage> createState() => _UserNewsPageState();
}

class _UserNewsPageState extends State<UserNewsPage> {
  int _currentBanner = 0;
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;

  List<Product> allProducts = [];
  bool isLoading = true;

  Future<void> fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      final loadedProducts =
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      setState(() {
        allProducts = loadedProducts;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _startAutoPlay();
  }

  List<Product> get trendingProducts => allProducts
      .where((p) => p.categories.any((c) => c.toLowerCase().contains('trending')))
      .toList();

  List<Product> get newProducts => allProducts
      .where((p) => p.categories.any((c) =>
          c.toLowerCase().contains('terbaru') ||
          c.toLowerCase().contains('new')))
      .toList();

  List<Product> get popularProducts => allProducts
      .where((p) => p.categories.any((c) =>
          c.toLowerCase().contains('populer') ||
          c.toLowerCase().contains('popular')))
      .toList();


  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (newProducts.isEmpty) return;
      final itemCount = newProducts.length;
      if (itemCount <= 1) return;

      setState(() {
        _currentBanner = (_currentBanner + 1) % itemCount;
      });

      _pageController.animateToPage(
        _currentBanner,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel(); 
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: NewsHeader()),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (trendingProducts.isNotEmpty)
                  _buildSection('Trending', trendingProducts, isHorizontal: true),
                if (newProducts.isNotEmpty)
                  _buildSection('Terbaru', newProducts, useCarousel: true),
                if (popularProducts.isNotEmpty)
                  _buildSection('Populer', popularProducts),
                SizedBox(height: 80.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<Product> products, {
    bool isHorizontal = false,
    bool useCarousel = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
        ),

        if (useCarousel)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: SizedBox(
                    height: 160.h,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentBanner = index);
                      },
                      itemCount: products.length,
                      itemBuilder: (context, index) => Image.asset(
                        products[index].imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(products.length, (index) {
                  bool isActive = index == _currentBanner;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    height: isActive ? 10.w : 8.w,
                    width: isActive ? 10.w : 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 12.h),
            ],
          )

        else if (isHorizontal)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildHorizontalList(products),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildVerticalCards(products),
          ),
      ],
    );
  }

  Widget _buildHorizontalList(List<Product> products) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 2,
    );
    return SizedBox(
      height: 180.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: products.length > 3 ? 3 : products.length,
        separatorBuilder: (_, __) => Container(
          width: 1.2,
          height: 135.h,
          color: Colors.grey.shade400,
          margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 135.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.asset(
                    product.imagePath,
                    fit: BoxFit.cover,
                    height: 100.h,
                    width: double.infinity,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  formatCurrency.format(product.price),
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    fontFamily: "Poppins",
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black87,
                    fontFamily: "Poppins",
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalCards(List<Product> products) {
    final displayProducts =
        products.length > 2 ? products.sublist(0, 2) : products;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: displayProducts.map((product) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: NewsProductCard(product: product),
          );
        }).toList(),
      ),
    );
  }
}
