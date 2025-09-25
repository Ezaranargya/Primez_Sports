import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/product_card.dart';
import 'widgets/logo_card.dart';
import 'brand_page.dart';

import 'pages/product/product_detail_page.dart' as user;

import 'user/product_page.dart';
import 'user/community_page.dart';
import 'user/news_page.dart';
import 'user/profile_page.dart';

import 'admin/product_page.dart';
import 'admin/community_page.dart';
import 'admin/news_page.dart';
import 'admin/profile_page.dart';
import 'models/product_model.dart';
import 'data/dummy_products.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = "";
  String selectedBrands = "";
  int selectedIndex = 0;
  String? userRole;
  bool isLoadingRole = true;

  final List<Product> dummy_products = [
   Product(
        id: "1", 
        name: "Nike Giannis Immortality4 EP",
        price: 1499000,
        imageUrl: "https://i.ibb.co.com/DPr3vv4X/nike-giannis.png",
        description: "Sepatu basket terbaru",
        category: "Trending",
        ),
      Product(
        id: "2", 
        name: "Nike Zoom Mercurial Superfly 9 Academy",
        price: 1549000,
        imageUrl: "https://i.ibb.co.com/JwWvQQ70/nike-zoom.png",
        description: "Sepatu sepak bola terbaik",
        category: "Trending",
        ),
      Product(
        id: "3" ,
        name: "Puma Ultra 5 Carbon LE FG White-Ultra Blue",
        price: 1959440,
        imageUrl:"https://i.ibb.co.com/QvqRGh7X/Puma-Ultra-5-Carbon-LE-FG-White-Ultra-Blue.png",
      description: "Sepatu sepak bola populer saat ini",
      category: "Terbaru"
      ),
      Product(
        id: "4",
        name: "Adidas Crazyflight Bounce 3 Volleyball Shoes",
        price: 2290400,
        imageUrl:"https://i.ibb.co.com/nMm9Fkj7/Adidas-Crazyflight-Bounce-3-Volleyball-Shoes.png",
        description: "Sepatu voli terbaik Adidas",
        category: "Terbaru",
        ),
  ];

  final productObjects = dummyProducts;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
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
  setState(() {
    selectedIndex = index;
  });

  switch (index) {
    case 0:
      break;

    case 1:
      if (userRole == 'admin') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminProductPage(initialProducts: productObjects)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserProductPage()),
        );
      }
      break;

    case 2:
      if (userRole == 'admin') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminCommunityPage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserCommunityPage()),
        );
      }
      break;

    case 3:
      if (userRole == 'admin') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminNewsPage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserNewsPage()),
        );
      }
      break;

    case 4:
      if (userRole == 'admin') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminProfilePage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserProfilePage()),
        );
      }
      break;
  }
}

  @override
  Widget build(BuildContext context) {
    final filteredProducts = productObjects.where((product) {
      final name = product.name.toLowerCase();
      final matchesSearch = name.contains(searchQuery.toLowerCase());
      final matchesBrands =
          selectedBrands.isEmpty || name.contains(selectedBrands.toLowerCase());
      return matchesSearch && matchesBrands;
    }).toList();

    if (isLoadingRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
            if (userRole == 'admin') ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            ],
          ],
        ),
        actions: [
          if (userRole == 'admin')
            IconButton(
              icon:
                  const Icon(Icons.admin_panel_settings, color: Colors.white),
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
              final matches = productObjects
                  .where((p) =>
                      p.name.toLowerCase() == value.toLowerCase())
                  .toList();

              if (matches.isNotEmpty) {
                final match = matches.first;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        user.ProductDetailPage(product: match),
                  ),
                );
              }
            },
            decoration: InputDecoration(
              hintText: "Cari sepatu...",
              hintStyle: const TextStyle(fontFamily: "Poppins"),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (searchQuery.isNotEmpty || selectedBrands.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hasil pencarian (${filteredProducts.length})",
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (selectedBrands.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedBrands = "";
                      });
                    },
                    child: const Text("Reset",
                        style: TextStyle(fontFamily: "Poppins")),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: filteredProducts.map((product) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              user.ProductDetailPage(product: product),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: ProductCard(product:product, isHorizontal: true),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            const Text(
              "Trending",
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
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
                        MaterialPageRoute(
                          builder: (_) =>
                              user.ProductDetailPage(product: product),
                        ),
                      );
                    },
                    child: ProductCard(product:product,isHorizontal: true),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Terbaru",
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
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
                        MaterialPageRoute(
                          builder: (_) =>
                              user.ProductDetailPage(product: product),
                        ),
                      );
                    },
                    child: ProductCard(product:product,isHorizontal: true,),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Brands",
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  logoCard(
                    "https://i.ibb.co.com/pjvscvQR/logo-nike.png",
                    "Nike",
                    (brands) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandPage(
                            brandName: "",
                            brandLogo: "",
                            products: productObjects,
                          ),
                        ),
                      );
                    },
                  ),
                  logoCard(
                    "https://i.ibb.co.com/zWkbN6gx/logo-jordan.png",
                    "Jordan",
                    (brands) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandPage(
                            brandName: "",
                            brandLogo: "",
                            products: productObjects,
                          ),
                        ),
                      );
                    },
                  ),
                  logoCard(
                    "https://i.ibb.co.com/8gP849Bm/logo-adidas.png",
                    "Adidas",
                    (brands) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandPage(
                            brandName: "",
                            brandLogo: "",
                            products: productObjects,
                          ),
                        ),
                      );
                    },
                  ),
                  logoCard(
                    "https://i.ibb.co.com/fGpWwGDP/logo-under-armour.png",
                    "Under Armour",
                    (brands) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandPage(
                            brandName: "",
                            brandLogo: "",
                            products: productObjects,
                          ),
                        ),
                      );
                    },
                  ),
                  logoCard(
                    "https://i.ibb.co.com/mrSH0jfT/logo-puma.png",
                    "Puma",
                    (brands) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandPage(
                            brandName: "",
                            brandLogo: "",
                            products: productObjects,
                          ),
                        ),
                      );
                    },
                  ),
                  logoCard(
                    "https://i.ibb.co.com/TqYxvdLR/logo-mizuno.png",
                    "Mizuno",
                    (brands) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandPage(
                            brandName: "",
                            brandLogo: "",
                            products: productObjects,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ],
      ),
      bottomNavigationBar: Container(
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
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
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
      ),
    );
  }
}
