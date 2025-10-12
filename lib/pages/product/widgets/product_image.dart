import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String imageUrl;

  const ProductImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final bool isNetworkImage = imageUrl.startsWith('http');

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl.isNotEmpty
            ? (isNetworkImage
                ? Image.network(
                    imageUrl,
                    height: 250,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    imageUrl,
                    height: 250,
                    fit: BoxFit.contain,
                  ))
            : const Icon(
                Icons.image,
                size: 200,
                color: Colors.grey,
              ),
      ),
    );
  }
}
