  import 'package:flutter/material.dart';
  import '../widgets/product_card.dart';
  import '../widgets/logo_card.dart';
  import '../brand_page.dart';
  import '../admin/product_page.dart';
  import '../admin/community_page.dart';
  import '../admin/news_page.dart';
  import '../admin/profile_page.dart';
  import '../models/product_model.dart';

  class AdminHomePage extends StatefulWidget {
    const AdminHomePage({super.key});

    @override
    State<AdminHomePage> createState() => _AdminHomePageState();
  }

  class _AdminHomePageState extends State<AdminHomePage> {
    int selectedIndex = 0;

    final List<Product> dummyProducts = [
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
      category: "Terbaru",
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

    void onItemTapped(int index) {
      setState(() {
        selectedIndex = index;
      });

      switch (index) {
        case 0:
          break;
        case 1:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminProductPage(initialProducts: dummyProducts)),
          );
          break;
        case 2:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCommunityPage()),
          );
          break;
        case 3:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminNewsPage()),
          );
          break;
        case 4:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminProfilePage()),
          );
          break;
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: const Color(0xFFE53E3E),
          title: const Text(
            'Primez Sports',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                "https://i.ibb.co.com/SDtmfvv3/sepatu-awal.jpg",
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: "Trending",
              products: dummyProducts.take(2).toList(),
            ),

            _buildSection(
              title: "Terbaru",
              products: dummyProducts.skip(2).take(2).toList(),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Brand",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                      },
                      child: const Text("Tambah"),
                    ),
                    TextButton(
                      onPressed: () {
                      },
                      child: const Text("Edit"),
                    ),
                  ],
                ),
              ],
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
                    (brands) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandPage(
                          brandName: "Nike",
                          brandLogo: "", 
                          products: dummyProducts,
                          ),
                        ),
                      );
                    },
                  ),
                  logoCard(
                          "https://i.ibb.co.com/Z129BtG3/logo-jordan.png",
                          "Jordan",
                          (brands) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BrandPage(
                                  brandName: "Jordan",
                                  brandLogo: "",
                                  products: dummyProducts,
                                ),
                              ),
                            );
                          },
                        ),
                  logoCard(
                    "https://i.ibb.co.com/hxv0zX6Z/logo-adidas.png",
                    "Adidas",
                    (brands) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandPage(
                          brandName: "Adidas",
                          brandLogo: "", 
                          products: dummyProducts,
                          ),
                        ),
                      );
                    },
                  ),
                  logoCard(
                          "https://i.ibb.co.com/Rk5zWTPR/logo-under-armour.png",
                          "Under Armour",
                          (brands) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BrandPage(
                                  brandName: "Under Armour",
                                  brandLogo: "",
                                  products: dummyProducts,
                                ),
                              ),
                            );
                          },
                        ),
                  logoCard(
                    "https://i.ibb.co.com/Z1XQwtnw/logo-puma.png",
                    "Puma",
                    (brands) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandPage(
                          brandName: "Puma",
                          brandLogo: "", 
                          products: dummyProducts,
                          ),
                        ),
                      );
                    },
                  ),
                  logoCard(
                          "https://i.ibb.co.com/dsWp7GbJ/logo-mizuno.png",
                          "Mizuno",
                          (brands) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BrandPage(
                                  brandName: "Mizuno",
                                  brandLogo: "",
                                  products: dummyProducts,
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFE53E3E),
          unselectedItemColor: Colors.grey,
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Produk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Komunitas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Admin',
            ),
          ],
        ),
      );
    }

   Widget _buildSection({
  required String title,
  required List<Product> products,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: "Poppins",
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              TextButton(onPressed: () {}, child: const Text("Tambah")),
              TextButton(onPressed: () {}, child: const Text("Edit")),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 250,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: products.map((product) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(product: product),
                  ),
                );
              },
              child: ProductCard(product:product,isHorizontal: true),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
  }
