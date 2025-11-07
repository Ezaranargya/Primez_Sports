import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/pages/user/widgets/banner_carousel.dart';
import 'package:my_app/models/product_model.dart'; // ⬅️ penting
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsBanner extends StatelessWidget {
  const NewsBanner({super.key});

  Future<List<Product>> fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .limit(3)
        .get();

    // ✅ ubah setiap dokumen menjadi objek Product
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: fetchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 180.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 180.h,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 180.h,
            child: const Center(child: Text('No products found')),
          );
        } else {
          final products = snapshot.data!;

          return BannerCarousel(
            banners: products, // ✅ Sekarang sudah List<Product>
            height: 180.h,
            borderRadius: 16.r,
            activeColor: Colors.redAccent,
            onBannerTap: (product) {
              print("Banner ${product.name} diklik");
            },
          );
        }
      },
    );
  }
}
