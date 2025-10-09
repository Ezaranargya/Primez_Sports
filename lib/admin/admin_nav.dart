import 'package:flutter/material.dart';
import 'package:my_app/admin/pages/admin_home_page.dart';
import 'product_page.dart';
import 'community_page.dart';
import 'news_page.dart';
import 'profile_page.dart';
import '../models/product_model.dart'; 

class AdminNav extends StatefulWidget {
  const AdminNav({super.key});

  @override
  State<AdminNav> createState() => _AdminNavState();
}

class _AdminNavState extends State<AdminNav> {
  int _selectedIndex = 0;

  final List<Product> dummyProducts= [
    Product(
      id: "1",
      name: "Nike Giannis Immortality4 EP",
      brand: "Nike",
      price: 1499000,
      imageUrl: "https://i.ibb.co.com/DPr3vv4X/nike-giannis.png",
      description: "Sepatu basket terbaru",
      categories: ["basketball","Trending"],
    ),
    Product(
      id: "2",
      name: "Nike Zoom Mercurial Superfly 9 Academy",
      brand: "Nike",
      price: 1549000,
      imageUrl: "https://i.ibb.co.com/JwWvQQ70/nike-zoom.png",
      description: "Sepatu sepak bola terbaik",
      categories: ["soccer","Trending"],
    ),
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const AdminHomePage(),
      AdminProductPage(initialProducts: dummyProducts),
      const AdminCommunityPage(),
      const AdminNewsPage(),
      const AdminProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Produk"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: "News"),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Profile"),
        ],
      ),
    );
  }
}
