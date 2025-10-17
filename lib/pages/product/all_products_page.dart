import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/community/widgets/product_info_card.dart';

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  bool isLoading = true;
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('products').get();

      final loadedProducts =
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      setState(() {
        products = loadedProducts;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.only(bottom: 20.h),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductInfoCard(product: products[index]);
              },
            ),
    );
  }
}
