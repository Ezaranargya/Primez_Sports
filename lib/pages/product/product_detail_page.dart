import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:share_plus/share_plus.dart';

import 'widgets/product_image.dart';
import 'widgets/product_info.dart';
import 'widgets/action_buttons.dart';
import 'purchase_options_list.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final bool isAdmin;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.isAdmin = false,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool isFavorite = false;
  bool isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final favDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.product.id)
          .get();

      if (mounted) setState(() => isFavorite = favDoc.exists);
    } catch (e) {
      debugPrint('Error checking favorite: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Silakan login terlebih dahulu")),
        );
      }
      return;
    }
    if (isLoadingFavorite) return;

    setState(() => isLoadingFavorite = true);

    try {
      final favRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.product.id);

      if (isFavorite) {
        await favRef.delete();
        if (mounted) {
          setState(() {
            isFavorite = false;
            isLoadingFavorite = false;
          });
          _showSnackBar("${widget.product.name} dihapus dari favorite");
        }
      } else {
        await favRef.set({
          'id': widget.product.id,
          'name': widget.product.name,
          'description': widget.product.description,
          'price': widget.product.price,
          'imageUrl': widget.product.imageUrl,
          'addedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() {
            isFavorite = true;
            isLoadingFavorite = false;
          });
          _showSnackBar("${widget.product.name} ditambahkan ke favorite");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingFavorite = false);
        _showSnackBar("Gagal mengubah status favorite");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18.sp),
        ),
        backgroundColor: const Color(0xFFE53E3E),
        actions: widget.isAdmin
            ? [
                IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(imageUrl: product.imageUrl),
            SizedBox(height: 16.h),

            ProductInfo(product: product),
            SizedBox(height: 24.h),
            if (product.purchaseOptions.isNotEmpty)
              PurchaseOptionsList(options: product.purchaseOptions),

            SizedBox(height: 24.h),
            ActionButtons(
              isFavorite: isFavorite,
              isLoadingFavorite: isLoadingFavorite,
              onFavoriteTap: _toggleFavorite,
              onShareTap: () => Share.share(
                "Cek produk ini: ${product.name}\nHarga: ${Formatter.currency(product.price)}",
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}