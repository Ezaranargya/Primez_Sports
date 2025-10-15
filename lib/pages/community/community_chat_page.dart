import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/data/dummy_products.dart';
import 'package:my_app/theme/app_colors.dart';
import 'widgets/product_info_card.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/purchase_options_list.dart'; 

class CommunityChatPage extends StatelessWidget {
  final String brand;

  const CommunityChatPage({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    final List<Product> brandProducts =
    AdminData.dummyProducts.where((p) => p.brand == brand).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat Komunitas $brand",
          style: TextStyle(fontSize: 18.sp, color: AppColors.secondary)),
          backgroundColor: AppColors.primary,
          centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: brandProducts.length,
        itemBuilder: (context, index) {
          final product = brandProducts[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Admin ${product.brand}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              ProductInfoCard(
                product: product, 
                )
            ],
          );
        },
      ),
    );
  }
}
