import 'package:flutter/material.dart';

class UserNewsPage extends StatefulWidget {
  const UserNewsPage({super.key});

  @override
  State<UserNewsPage> createState() => _UserNewsPageState();
}

class _UserNewsPageState extends State<UserNewsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedIndex = 3; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        break;
      case 2:
        break;
      case 3:
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("News"),
        backgroundColor: const Color(0xFFE53E3E),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrending(),
          _buildTerbaru(),
          _buildPopuler(),
        ],
      ),
    );
  }

  Widget _buildTrending() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: _productCard(
                "https://i.ibb.co.com/DPr3vv4X/nike-giannis.png",
                "Nike Giannis Immortality4 EP",
                "Rp 1.499.000",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _productCard(
                "https://i.ibb.co.com/JwWvQQ70/nike-zoom.png",
                "Nike Zoom Mercurial Superfly 9 Academy",
                "Rp 1.549.000",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTerbaru() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _newsCard(
          "https://i.ibb.co.com/5WyRvspr/what-the.png",
          "KOBE 8 PROTRO What the Kobe?",
          "Koleksi terbaru Nike Kobe Protro",
        ),
      ],
    );
  }

  Widget _buildPopuler() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _newsCard(
          "https://i.ibb.co.com/zT5rwJ6g/images-q-tbn-ANd9-Gc-Q1-QYZNH0y-Dyog-JM5-LJKVXvu-M06-NGg2-FPC-JA-s.jpg",
          "Puma Ultra 6 Dare To",
          "Puma Official",
        ),
      ],
    );
  }

  Widget _productCard(String imageUrl, String title, String price) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Image.network(imageUrl, height: 100, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Text(price, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _newsCard(String imageUrl, String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(imageUrl.isNotEmpty ? imageUrl : "", fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                )),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
