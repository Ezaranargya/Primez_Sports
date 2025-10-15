import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/pages/user/widgets/banner_carousel.dart';
import 'package:my_app/data/dummy_products.dart';

class NewsBanner extends StatelessWidget {
  const NewsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final products = AdminData.dummyProducts;
    return BannerCarousel(
      banners: [
       {"image": "assets/Nike_Giannis_Immortality_4_1.png", "product": products[0]},
       {"image": "assets/Sepak_Bola_PUMA_x_NEYMAR_JR_FUTURE_7_ULTIMATE_FGAG_1.png", "product": products[1]},
       {"image": "assets/Mizuno_Wave_Momentum_3_1.png", "product": products[2]},
      ],
      height: 180.h,
      borderRadius: 16.r,
      activeColor: Colors.redAccent,
      onBannerTap: (index) {
        print("Banner $index diklik");
      },
    );
  }
}
