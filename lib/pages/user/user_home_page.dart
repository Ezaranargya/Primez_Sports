import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/data/dummy_products.dart';
import 'package:my_app/pages/user/home_content_page.dart';
import '../../brand_page.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/pages/favorite/favorite_page.dart';
import 'package:my_app/pages/community/community_page.dart';
import 'package:my_app/pages/News/news_page.dart';
import 'package:my_app/pages/profile/profile_page.dart';
import 'package:my_app/pages/product/product_page.dart';
import 'package:my_app/providers/favorite_provider.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  String selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    loadAllProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().loadFavorites();
    });
  }
  List<Widget> get _pages {
    return [
      HomeContentPage(allProducts: allProducts),
      const UserFavoritePage(),
      const UserCommunityPage(),
      const UserNewsPage(),
      const UserProfilePage(),
    ];
  }

  Future<void> loadAllProducts() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('products').get();
      final products = snapshot.docs.map((doc) {
        return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      setState(() {
        allProducts = products;
        filteredProducts = products;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        allProducts = UserData.products;
        filteredProducts = UserData.products;
      });
    }
  }

  void filteredProductsByCategory(String category) {
    setState(() {
      selectedCategory = category;
      if (category == 'all') {
        filteredProducts = allProducts;
      } else {
        filteredProducts = allProducts
            .where((product) => product.categories.any(
                (c) => c.toLowerCase().contains(category.toLowerCase())))
            .toList();
      }
    });
  }

  void onItemTapped(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
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