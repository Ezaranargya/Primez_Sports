import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';
import 'widgets/product_info_card.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/purchase_options_list.dart'; 

class CommunityChatPage extends StatelessWidget {
  final String brand;

  const CommunityChatPage({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    final List<PurchaseOption> purchaseOptions = [
      PurchaseOption(
        price: 839300.0,
        storeName: "Shopee",
        logoUrl: "https://i.ibb.co.com/mFDsdnqf/2417d27bc0514b4d5c79025f47163c42.jpg",
        link: "https://shopee.co.id/-BEST-SELLER-Sepatu-Basket-Nike-giannis-immortality-4-ep-ORIGINAL-FQ3681-500-FQ3681-002-i.10262456.22351075298",
      ),
      PurchaseOption(
        price: 899150.0,
        storeName: "Tokopedia",
        logoUrl: "https://i.ibb.co.com/SXd39JB3/logo-tokopedia-brand-online-shopping-shopee-png-favpng-Us-Ut-Dw2-F9hy3n1-APHVC37k-Wr-P.jpg",
        link: "https://www.tokopedia.com/indohypesneakers/nike-giannis-immortality-4-ep-halloween-xdr-1730194039838377455?extParam=ivf%3Dfalse%26keyword%3Dnike+giannis+immortality+4%26src%3Dsearch",
      ),
      PurchaseOption(
        price: 1079000.0,
        storeName: "Blibli",
        logoUrl: "https://i.ibb.co.com/pBZ5KV1V/f760162c99d81ac7bd0e7462ace7da8f.jpg",
        link: "https://www.blibli.com/p/nike-men-basketball-giannis-immortality-4-halloween-ep-shoes-sepatu-basket-pria-fq3681-301/is--NIE-12227-12368-00012?pickupPointCode=PP-3537944",
      ),
      PurchaseOption(
        price: 958000.0,
        storeName: "Nike Official",
        logoUrl: "https://i.ibb.co.com/TB1Wb1s4/logo-nike.png",
        link: "https://www.nike.com/id/t/giannis-immortality-4-ep-basketball-shoes-4MTsCH",
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat Komunitas $brand",
          style: TextStyle(fontSize: 18.sp, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Admin",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),

            const ProductInfoCard(
              imagePath: "assets/nike_giannis.png",
              description:
                  "Nike Giannis Immortality 4 EP (NIKFQ3681301) adalah sepatu basket low-top ringan dengan midsole empuk untuk kenyamanan, outsole karet berpola multidireksi untuk grip maksimal, serta upper mesh yang menjaga sirkulasi udara. Stabil dan fleksibel, cocok bagi pemain cepat yang mengejar performa optimal.",
            ),

            SizedBox(height: 16.h),

            // ini bagian expandable list seperti gambar kamu
            PurchaseOptionsList(options: purchaseOptions),
          ],
        ),
      ),
    );
  }
}
