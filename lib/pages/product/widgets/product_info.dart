import 'package:flutter/material.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/utils/formatter.dart';

class ProductInfo extends StatelessWidget {
  final Product product;

  const ProductInfo({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          Formatter.formatPrice(product.price),
          style: const TextStyle(fontSize: 18, color: Color(0xFFE53E3E), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          product.description,
          style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
        ),
      ],
    );
  }
}