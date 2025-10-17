import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/pages/user/widgets/banner_carousel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsBanner extends StatelessWidget {
  const NewsBanner({super.key});

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .limit(3)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
            banners: [
              {
                "image": "assets/Nike_Giannis_Immortality_4_1.png",
                "product": products[0]
              },
              {
                "image": "assets/Sepak_Bola_PUMA_x_NEYMAR_JR_FUTURE_7_ULTIMATE_FGAG_1.png",
                "product": products[1]
              },
              {
                "image": "assets/Mizuno_Wave_Momentum_3_1.png",
                "product": products[2]
              },
            ],
            height: 180.h,
            borderRadius: 16.r,
            activeColor: Colors.redAccent,
            onBannerTap: (index) {
              print("Banner $index diklik");
            },
          );
        }
      },
    );
  }
}
