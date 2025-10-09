import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/brand_page.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/user/widgets/brand_section.dart';
import 'package:my_app/pages/user/widgets/home_header.dart';
import 'package:my_app/pages/user/widgets/new_section.dart';
import 'package:my_app/pages/user/widgets/product_section.dart';
import 'package:my_app/pages/user/widgets/logo_card.dart';
import 'package:my_app/pages/product/category_products_page.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/data/dummy_products.dart';
import 'package:my_app/pages/user/widgets/product_card.dart';
import 'package:my_app/pages/user/widgets/trending_section.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/product_utils.dart';
import 'package:my_app/pages/user/widgets/banner_carousel.dart';

Future<List<Product>> fetchProducts() async {
  final snapshot = await FirebaseFirestore.instance.collection('products').get();
  return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
}

void navigateToHome(BuildContext context, List<Product> loadedProducts) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => HomeContentPage(allProducts: loadedProducts),
    ),
  );
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
  String userName = "";
  bool isLoading = false;
  List<Product> loadedProducts = [];

  final List<Map<String, String>> categories = [
    {"display": "Basketball Shoes", "filter": "basketball"},
    {"display": "Soccer Shoes", "filter": "soccer"},
    {"display": "Volleyball Shoes", "filter": "volleyball"},
  ];

  List<Product> get currentProducts {
    return widget.allProducts.isNotEmpty ? widget.allProducts : UserData.products;
  }

  List<Product> get filteredProducts {
    return currentProducts.where((product) {
      final name = product.name.toLowerCase();
      final productCategories = product.categories
          .map((c) => c.toLowerCase())
          .toList();

      final matchesSearch = searchQuery.isEmpty ||
          name.contains(searchQuery.toLowerCase()) ||
          productCategories.any((c) => 
              c.contains(searchQuery.toLowerCase()));

      bool matchesCategory = true;
      if (selectedCategory.isNotEmpty) {
        matchesCategory = _checkCategoryMatch(
          selectedCategory,
          name,
          productCategories,
        );
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  bool _checkCategoryMatch(
    String category,
    String name,
    List<String> productCategories,
  ) {
    switch (category) {
      case 'basketball':
        return name.contains('basket') ||
            name.contains('basketball') ||
            productCategories.any((c) => 
                c.contains('basket') || c.contains('basketball'));
      case 'soccer':
        return name.contains('soccer') ||
            name.contains('football') ||
            name.contains('bola') ||
            productCategories.any((c) =>
                c.contains('soccer') ||
                c.contains('football') ||
                c.contains('bola'));
      case 'volleyball':
        return name.contains('volleyball') ||
            name.contains('voli') ||
            name.contains('volley') ||
            productCategories.any((c) =>
                c.contains('volleyball') ||
                c.contains('voli') ||
                c.contains('volley'));
      default:
        return productCategories.any((c) => 
                c.contains(category.toLowerCase())) ||
            name.contains(category.toLowerCase());
    }
  }

  List<Product> get trendingProducts {
    return currentProducts.where((p) => p.categories.any((c) =>
        c.toLowerCase().contains("trending") ||
        c.toLowerCase().contains("populer"))).toList();
  }

  List<Product> get newProducts {
    return currentProducts.where((p) => p.categories.any((c) =>
        c.toLowerCase().contains("terbaru") ||
        c.toLowerCase().contains("new"))).toList();
  }

  String getCategoryDisplayName(String categoryFilter) {
    for (final category in categories) {
      if (category["filter"] == categoryFilter) {
        return category["display"] !;
      }
    }
    return categoryFilter.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => isLoading = true);

      if (widget.allProducts.isEmpty) {
        final products = await fetchProducts();
        setState(() {
          loadedProducts = products.isNotEmpty ? products : UserData.products;
          isLoading = false;
        });
      } else {
        setState(() {
          loadedProducts = widget.allProducts;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        loadedProducts = UserData.products;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentProducts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64, 
                color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "Tidak ada produk",
                  style: TextStyle(fontSize: 18,color: Colors.grey),
                ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(160), 
            child: HomeHeader(
              userName: userName, 
              searchQuery: searchQuery, 
              selectedCategory: selectedCategory, 
              categories: categories,
              onSearchChanged: (value) => setState(() => searchQuery = value),
              onCategorySelected: (category) => setState(() {
                selectedCategory = selectedCategory == category ? "" : category;
              }),
                ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  if (searchQuery.isNotEmpty || selectedCategory.isNotEmpty)
                  ProductSection(
                    title: selectedCategory.isNotEmpty
                    ? "${getCategoryDisplayName(selectedCategory)}"
                    : "Hasil pencarian (${filteredProducts.length})", 
                    products: filteredProducts,
                    isWide: isWide,
                    )
                    else 
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BannerCarousel(),
                        const SizedBox(height: 20),

                        if (trendingProducts.isNotEmpty)...[
                          TrendingSection(
                            title: "Trending", 
                            produtcs: trendingProducts,
                            ),
                            const SizedBox(height: 20),
                        ],

                        if (newProducts.isNotEmpty)...[
                          NewSection(
                            title: "Terbaru", 
                            products: newProducts,
                            ),
                        ],

                        BrandSection(products: currentProducts),
                        const SizedBox(height: 80),
                ],
              ),
              ],
              ),
            ),
        );
      },
      );
  }
  Widget _buildBannerImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Image.network(
        "https://i.ibb.co.com/VcBqfVFQ/sepatu-awal.jpg",
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context,error,stackTrace) {
          return Container(
            height: 120.h,
            width: double.infinity,
            child: const Center(
              child: Icon(Icons.image, size: 50),
            ),
          );
        },
      ),
    );
  }
}