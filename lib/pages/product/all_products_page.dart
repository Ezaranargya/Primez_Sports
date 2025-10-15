import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/data/dummy_products.dart';
import 'package:my_app/pages/community/widgets/product_info_card.dart';

class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(bottom: 20.h),
        itemCount: AdminData.dummyProducts.length,
        itemBuilder: (context, index) {
          return ProductInfoCard(product: AdminData.dummyProducts[index]);
        },
        ),
    );
  }
}