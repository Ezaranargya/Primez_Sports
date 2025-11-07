import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:my_app/pages/user/home_content_page.dart';

class HomeContentPage extends StatefulWidget {
  final List<Product> allProducts;

  const HomeContentPage({super.key, required this.allProducts});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  String selectedCategory = '';

  List<Product> filterProductsByCategory(String categoryKey) {
    if (categoryKey.isEmpty) return widget.allProducts;
    return widget.allProducts
        .where((product) => product.categories.contains(categoryKey))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterProductsByCategory(selectedCategory);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          Wrap(
            spacing: 10,
            children: ['Shoes', 'Basket', 'Soccer', 'Voli'].map((category) {
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedCategory = category;
                  });
                },
                child: Text(category),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Produk tidak ditemukan'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(product.categories.join(", ")),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
