import 'package:flutter/material.dart';
import '../../models/product_model.dart';

class AdminProductDetailPage extends StatelessWidget {
  final Product product;

  const AdminProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            product.imageUrl.isNotEmpty
                ? Image.network(product.imageUrl,
                    height: 200, fit: BoxFit.cover)
                : const Icon(Icons.image, size: 200, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Rp ${product.price.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 12),
            Text(
              product.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
