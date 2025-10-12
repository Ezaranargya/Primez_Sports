import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'widgets/product_image.dart';
import 'widgets/product_info.dart';
import 'widgets/action_buttons.dart';
import 'purchase_options_list.dart';
import 'package:my_app/providers/favorite_provider.dart';

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
  bool _isLoadingFavorite = false;

  Future<void> _toggleFavorite(BuildContext context) async {
    if (_isLoadingFavorite) return;

    setState(() => _isLoadingFavorite = true);

    try {
      final favoriteProvider = context.read<FavoriteProvider>();
      final wasFavorite = favoriteProvider.isFavorite(widget.product.id);

      await favoriteProvider.toggleFavorite(widget.product);

      if (!mounted) return;

      _showSnackBar(
        wasFavorite
            ? '${widget.product.name} dihapus dari favorite'
            : '${widget.product.name} ditambahkan ke favorite',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengubah status favorite');
    } finally {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _shareProduct() {
    final product = widget.product;
    Share.share(
      'Cek produk ini di Primez Sports!\n\n'
      '${product.name}\nHarga: ${Formatter.currency(product.price)}',
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
          style: TextStyle(
            fontSize: 18.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFE53E3E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: widget.isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Produk',
                  onPressed: () {
                    // TODO: Implement edit functionality
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Hapus Produk',
                  onPressed: () {
                    // TODO: Implement delete functionality
                  },
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Product Image
            ProductImage(imageUrl: product.imageUrl),
            SizedBox(height: 16.h),

            /// 🔹 Product Info
            ProductInfo(product: product),
            SizedBox(height: 24.h),

            /// 🔹 Purchase Options
            if (product.purchaseOptions.isNotEmpty) ...[
              PurchaseOptionsList(options: product.purchaseOptions),
              SizedBox(height: 24.h),
            ],

            /// 🔹 Favorite & Share Buttons
            Consumer<FavoriteProvider>(
              builder: (context, favoriteProvider, _) {
                final isFavorite = favoriteProvider.isFavorite(product.id);
                return ActionButtons(
                  isFavorite: isFavorite,
                  isLoadingFavorite: _isLoadingFavorite,
                  onFavoriteTap: () => _toggleFavorite(context),
                  onShareTap: _shareProduct,
                );
              },
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
