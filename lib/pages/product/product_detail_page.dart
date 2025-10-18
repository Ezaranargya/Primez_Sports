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
import 'package:my_app/providers/widgets/favorite_button.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final bool isAdmin;
  final bool showFavoriteInAppBar;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.isAdmin = false,
    this.showFavoriteInAppBar = false,
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
      '${product.name}\nHarga: ${Formatter.formatPrice(product.price)}',
    );
  }

  List<Widget> _buildAppBarActions() {
    List<Widget> actions = [];

    if (widget.isAdmin) {
      actions.addAll([
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Produk',
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Hapus Produk',
          onPressed: () {},
        ),
      ]);
    } else if (widget.showFavoriteInAppBar) {
      actions.addAll([
        FavoriteButton(
          product: widget.product,
          size: 28,
          activeColor: Colors.red,
          inactiveColor: Colors.white,
        ),
        SizedBox(width: 8.w),
      ]);
    }

    return actions.isNotEmpty ? actions : [];
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
        actions: _buildAppBarActions(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(imageUrl: product.imagePath),
            SizedBox(height: 16.h),
            ProductInfo(
              product: product,
              showDescription: false,
            ),
            SizedBox(height: 24.h),
            if (product.description.isNotEmpty) ...[
              SizedBox(height: 12.h),
              
              Text(
                product.description,
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.6,
                  fontFamily: "Poppins",
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 24.h),
            ],
            if (product.purchaseOptions.isNotEmpty) ...[
              PurchaseOptionsList(options: product.purchaseOptions),
              SizedBox(height: 24.h),
            ] else ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Opsi pembelian tidak tersedia untuk produk ini',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.orange.shade700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
            if (!widget.showFavoriteInAppBar)
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