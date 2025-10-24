import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/services/product_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/pages/user/home_content_page.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/pages/favorite/favorite_page.dart';
import 'package:my_app/pages/community/community_page.dart';
import 'package:my_app/pages/news/news_page.dart';
import 'package:my_app/pages/profile/profile_page.dart';
import 'package:my_app/providers/favorite_provider.dart';
import 'package:my_app/pages/user/widgets/product_card.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  
  int selectedIndex = 0;
  String selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().loadFavorites();
    });
  }

  List<Widget> _pages(List<Product> allProducts) {
    return [
      HomeContentPage(allProducts: allProducts),
      const UserFavoritesPage(),
      const UserCommunityPage(),
      const UserNewsPage(),
      const UserProfilePage(),
    ];
  }

  void onItemTapped(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Product>>(
        stream: _productService.getAllProducts(),
        builder: (context, snapshot) {
          // 🐛 Debug prints
          print('📱 Connection State: ${snapshot.connectionState}');
          print('❌ Has Error: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('⚠️ Error: ${snapshot.error}');
          }
          print('✅ Has Data: ${snapshot.hasData}');
          print('📊 Data Length: ${snapshot.data?.length ?? 0}');

          // Handle error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    'Terjadi Kesalahan',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Get products data
          final allProducts = snapshot.data ?? [];

          // Handle empty state
          if (allProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'Belum Ada Produk',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Produk akan muncul di sini',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Display pages with products data
          return IndexedStack(
            index: selectedIndex,
            children: _pages(allProducts),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline), label: 'Favorite'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Komunitas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// 🔹 Alternative: Standalone Product List Page with StreamBuilder
class UserProductListPage extends StatefulWidget {
  const UserProductListPage({super.key});

  @override
  State<UserProductListPage> createState() => _UserProductListPageState();
}

class _UserProductListPageState extends State<UserProductListPage> {
  final ProductService _productService = ProductService();
  String selectedCategory = 'all';
  final List<String> categories = ['all', 'Basketball', 'Soccer', 'Volleyball'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Produk'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ChoiceChip(
                    label: Text(
                      category == 'all' ? 'Semua' : category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedCategory = category);
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: Colors.grey[200],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: selectedCategory == 'all'
            ? _productService.getAllProducts()
            : _productService.getProductsByCategory(selectedCategory),
        builder: (context, snapshot) {
          // Debug prints
          print('📱 Connection State: ${snapshot.connectionState}');
          print('❌ Has Error: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('⚠️ Error: ${snapshot.error}');
          }
          print('✅ Has Data: ${snapshot.hasData}');
          print('📊 Data Length: ${snapshot.data?.length ?? 0}');

          // Handle error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          // Handle loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? [];

          // Handle empty
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'Tidak ada produk',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Display products
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProductDetailPage(
                          product: product,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  width: 80.w,
                                  height: 80.w,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80.w,
                                    height: 80.w,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image_not_supported,
                                        size: 40.sp, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 80.w,
                                  height: 80.w,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image,
                                      size: 40.sp, color: Colors.grey),
                                ),
                        ),
                        SizedBox(width: 12.w),
                        
                        // Product Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                product.brand,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              if (product.purchaseOptions.isNotEmpty)
                                Text(
                                  product.purchaseOptions.first.formattedPrice,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Arrow icon
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}