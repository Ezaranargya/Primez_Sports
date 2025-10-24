import 'dart:convert';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String? imageBase64;
  final double width;
  final double height;
  final BoxFit fit;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.imageBase64,
    this.width = double.infinity,
    this.height = 250,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      return _buildFromBase64();
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _buildFromUrlOrAsset();
    } else {
      return _buildPlaceholder(Icons.image_not_supported);
    }
  }

  Widget _buildFromBase64() {
    try {
      final bytes = base64Decode(imageBase64!);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(Icons.broken_image),
      );
    } catch (e) {
      print('❌ Error decoding Base64: $e');
      return _buildPlaceholder(Icons.broken_image);
    }
  }

  Widget _buildFromUrlOrAsset() {
    final isNetworkImage = imageUrl!.startsWith('http');
    final imageWidget = isNetworkImage
        ? Image.network(
            imageUrl!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildPlaceholder(Icons.broken_image),
          )
        : Image.asset(
            imageUrl!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildPlaceholder(Icons.broken_image),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageWidget,
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(
        icon,
        size: 60,
        color: Colors.grey,
      ),
    );
  }
}
