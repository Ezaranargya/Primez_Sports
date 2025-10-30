import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/pages/user/widgets/logo_card.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/pages/user/widgets/product_card.dart';
import 'package:my_app/pages/product/product_page.dart';
import 'package:my_app/pages/community/community_page.dart';
import 'package:my_app/pages/news/news_page.dart';
import 'package:my_app/pages/profile/profile_page.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';
import 'admin/product/product_page.dart';
import 'admin/community/community_page.dart';
import 'admin/news/news_page.dart';
import 'admin/profile_page.dart';
import 'models/product_model.dart';
import 'brand_page.dart';

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> productObjects = [];
  String searchQuery = "";
  String selectedBrands = "";
  int selectedIndex = 0;
  String? userRole;
  bool isLoadingRole = true;
  bool isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _getProductsFromFirestore();
  }

  Future<void> _getProductsFromFirestore() async {
    try {
      print('📦 Fetching products from Firestore...');
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      
      final products = snapshot.docs.map((doc) {
        final product = Product.fromFirestore(doc);
        
        if (product.imageBase64 != null && product.imageBase64!.isNotEmpty) {
          print('✅ Product ${product.id} has imageBase64 (${product.imageBase64!.length} chars)');
        } else if (product.imageUrl.isNotEmpty) {
          print('ℹ️ Product ${product.id} has imageUrl: ${product.imageUrl}');
        } else {
          print('⚠️ Product ${product.id} has no image');
        }
        
        return product;
      }).toList();

      setState(() {
        productObjects = products;
        isLoadingProducts = false;
      });
      
      print('✅ Loaded ${products.length} products');
    } catch (e) {
      print("❌ Error fetching products: $e");
      setState(() => isLoadingProducts = false);
    }
  }

  Future<void> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userRole = userData['role'] ?? 'user';
            isLoadingRole = false;
          });
        } else {
          setState(() {
            userRole = user.email?.contains('admin') == true ? 'admin' : 'user';
            isLoadingRole = false;
          });
        }
      } catch (e) {
        setState(() {
          userRole = 'user';
          isLoadingRole = false;
        });
      }
    }
  }

  void onItemTapped(int index) {
    setState(() => selectedIndex = index);

    switch (index) {
      case 1:
        if (userRole == 'admin') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminProductPage()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProductPage()));
        }
        break;
      case 2:
        if (userRole == 'admin') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCommunityPage()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserCommunityPage()));
        }
        break;
      case 3:
        if (userRole == 'admin') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNewsPage()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserNewsPage()));
        }
        break;
      case 4:
        if (userRole == 'admin') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfilePage()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfilePage()));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingRole || isLoadingProducts) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredProducts = productObjects.where((product) {
      final name = product.name.toLowerCase();
      final matchesSearch = name.contains(searchQuery.toLowerCase());
      final matchesBrands =
          selectedBrands.isEmpty || name.contains(selectedBrands.toLowerCase());
      return matchesSearch && matchesBrands;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53E3E),
        title: Row(
          children: [
            Text(
              userRole == 'admin' ? 'Admin View' : 'Primez Sports',
              style: const TextStyle(color: Colors.white),
            ),
            if (userRole == 'admin')
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/admin_home');
              },
              tooltip: 'Admin Dashboard',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
                selectedBrands = "";
              });
            },
            decoration: InputDecoration(
              hintText: "Cari sepatu...",
              hintStyle: const TextStyle(fontFamily: "Poppins"),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (searchQuery.isNotEmpty || selectedBrands.isNotEmpty)
            _buildSearchResult(filteredProducts)
          else
            _buildHomeContent(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchResult(List<Product> filteredProducts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hasil pencarian (${filteredProducts.length})",
          style: const TextStyle(
            fontFamily: "Poppins",
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: filteredProducts.map((product) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserProductDetailPage(product: product)),
                  );
                },
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ProductCard(product: product, isHorizontal: true),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trending",
          style: TextStyle(fontFamily: "Poppins", fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: productObjects.take(2).map((product) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserProductDetailPage(product: product)),
                  );
                },
                child: ProductCard(product: product, isHorizontal: true),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Terbaru",
          style: TextStyle(fontFamily: "Poppins", fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: productObjects.skip(2).take(2).map((product) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserProductDetailPage(product: product)),
                  );
                },
                child: ProductCard(product: product, isHorizontal: true),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Brands",
          style: TextStyle(fontFamily: "Poppins", fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildBrandLogos(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBrandLogos() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          logoCard("https://i.ibb.co/pjvscvQR/logo-nike.png", "Nike", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BrandPage(
                  brandName: "Nike",
                  brandLogo: "https://i.ibb.co/pjvscvQR/logo-nike.png",
                  products: productObjects,
                ),
              ),
            );
          }),
          logoCard("https://i.ibb.co/zWkbN6gx/logo-jordan.png", "Jordan", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BrandPage(
                  brandName: "Jordan",
                  brandLogo: "https://i.ibb.co/zWkbN6gx/logo-jordan.png",
                  products: productObjects,
                ),
              ),
            );
          }),
          logoCard("https://i.ibb.co/8gP849Bm/logo-adidas.png", "Adidas", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BrandPage(
                  brandName: "Adidas",
                  brandLogo: "https://i.ibb.co/8gP849Bm/logo-adidas.png",
                  products: productObjects,
                ),
              ),
            );
          }),
          logoCard("https://i.ibb.co/fGpWwGDP/logo-under-armour.png", "Under Armour", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BrandPage(
                  brandName: "Under Armour",
                  brandLogo: "https://i.ibb.co/fGpWwGDP/logo-under-armour.png",
                  products: productObjects,
                ),
              ),
            );
          }),
          logoCard("https://i.ibb.co/mrSH0jfT/logo-puma.png", "Puma", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BrandPage(
                  brandName: "Puma",
                  brandLogo: "https://i.ibb.co/mrSH0jfT/logo-puma.png",
                  products: productObjects,
                ),
              ),
            );
          }),
          logoCard("https://i.ibb.co/TqYxvdLR/logo-mizuno.png", "Mizuno", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BrandPage(
                  brandName: "Mizuno",
                  brandLogo: "https://i.ibb.co/TqYxvdLR/logo-mizuno.png",
                  products: productObjects,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE53E3E),
        unselectedItemColor: Colors.grey,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            activeIcon: const Icon(Icons.favorite),
            label: userRole == 'admin' ? 'Admin Favorites' : 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: userRole == 'admin' ? 'Admin Chat' : 'Chat Komunitas',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.newspaper_outlined),
            activeIcon: const Icon(Icons.newspaper),
            label: userRole == 'admin' ? 'Admin News' : 'News',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: userRole == 'admin' ? 'Admin Profile' : 'Profile',
          ),
        ],
      ),
    );
  }
}