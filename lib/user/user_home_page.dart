import 'package:flutter/material.dart';
import 'package:my_app/utils/formatter.dart';
import '../widgets/product_card.dart';
import '../brand_page.dart';
import '../pages/product/product_detail_page.dart';
import 'community_page.dart';
import 'news_page.dart';
import 'profile_page.dart';
import '../models/product_model.dart';
import 'favorite_page.dart';
import '../data/dummy_products.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomeContentPage(),
      UserFavoritePage(),
      UserCommunityPage(),
      UserNewsPage(),
      UserProfilePage(),
    ];
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
        selectedItemColor: const Color(0xFFE53E3E),
        unselectedItemColor: Colors.grey,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper_outlined), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  String searchQuery = "";
  String selectedCategory = "";

  final List<String> categories = [
    "Basketball shoes",
    "Soccer shoes",
    "Volleyball shoes",
  ];

  @override
  Widget build(BuildContext context) {
    final filteredProducts = dummyProducts.where((product) {
      final name = product.name.toLowerCase();
      final matchesSearch = searchQuery.isEmpty || name.contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory.isEmpty || name.contains(selectedCategory.toLowerCase());
      return matchesSearch && matchesCategory;
    }).toList();

    final trendingProducts = dummyProducts.where((p) => p.category == "trending").toList();
    final newProducts = dummyProducts.where((p) => p.category == "terbaru").toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(160),
            child: buildHeader(context),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                if (searchQuery.isNotEmpty || selectedCategory.isNotEmpty)
                  buildProductSection(
                    context,
                    title: selectedCategory.isNotEmpty
                        ? "$selectedCategory (${filteredProducts.length})"
                        : "Hasil pencarian (${filteredProducts.length})",
                    products: filteredProducts,
                    isWide: isWide,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          "https://i.ibb.co.com/ZRDSyVBm/sepatu-awal.jpg",
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),

                      buildProductList("Trending", trendingProducts, isWide),
                      const SizedBox(height: 20),
                      buildProductList("Terbaru", newProducts, isWide),

                      const SizedBox(height: 20),
                      const Text(
                        "Brand",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            logoCard(
                              "https://i.ibb.co.com/pjvscvQR/logo-nike.png",
                              "Nike",
                            ),
                            logoCard(
                              "https://i.ibb.co.com/Z129BtG3/logo-jordan.png",
                              "Jordan",
                            ),
                            logoCard(
                              "https://i.ibb.co.com/hxv0zX6Z/logo-adidas.png",
                              "Adidas",
                            ),
                            logoCard(
                              "https://i.ibb.co.com/Rk5zWTPR/logo-under-armour.png",
                              "Under Armour",
                            ),
                            logoCard(
                              "https://i.ibb.co.com/Z1XQwtnw/logo-puma.png",
                              "Puma",
                            ),
                            logoCard(
                              "https://i.ibb.co.com/dsWp7GbJ/logo-mizuno.png",
                              "Mizuno",
                            ),
                          ],
                        ),
                      ),

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

  Widget buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: "Search for shoes...",
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none),
                      color: Colors.black87,
                      iconSize: 22,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(color: Color(0xFFE53E3E)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 40,
                child: Row(
                  children: List.generate(categories.length, (index) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory =
                                selectedCategory == categories[index] ? "" : categories[index];
                            searchQuery = "";
                          });
                        },
                        child: Text(
                          categories[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selectedCategory == categories[index]
                                ? Colors.yellow
                                : Colors.white,
                            fontWeight: selectedCategory == categories[index]
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 16,
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProductList(String title, List<Product> products, bool isWide) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: "Poppins",
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length >= 3 ? 3 : products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white),
                          ),
                          child: product.imageUrl.isNotEmpty
                          ? Image.network(product.imageUrl,fit: BoxFit.contain)
                          : const Icon(Icons.image, size: 80, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatter.currency(product.price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget logoCard(String logoUrl, String brandName) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BrandPage(
              brandName: brandName,
              brandLogo: logoUrl,
              products: dummyProducts,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Image.network(logoUrl, fit: BoxFit.contain),
      ),
    );
  }

  Widget buildProductSection(BuildContext context,
      {required String title, required List<Product> products, required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: "Poppins",
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (products.length > 2)
            TextButton(
              onPressed: () {},
              child: const Text("Lihat Semua",
                  style: TextStyle(color: Color(0xFFE53E3E), fontSize: 14, fontWeight: FontWeight.w500)),
            ),
        ]),
        const SizedBox(height: 12),
        if (products.isEmpty)
          const Center(child: Text("Produk tidak ditemukan"))
        else if (isWide)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2 / 3,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
                ),
                child: ProductCard(product: product, isHorizontal: false),
              );
            },
          )
        else
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return SizedBox(
                  width: 140,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
                    ),
                    child: ProductCard(product: product, isHorizontal: false),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
