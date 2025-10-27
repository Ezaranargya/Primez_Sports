import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/providers/favorite_provider.dart';
import 'package:my_app/providers/widgets/favorite_button.dart';
import 'package:my_app/services/product_service.dart';
import 'package:my_app/utils/formatter.dart';
import 'widgets/product_info.dart';
import 'widgets/action_buttons.dart';
import 'purchase_options_list.dart';

class UserProductDetailPage extends StatefulWidget {
  final Product product;
  final bool isAdmin;
  final bool showFavoriteInAppBar;

  const UserProductDetailPage({
    super.key,
    required this.product,
    this.isAdmin = false,
    this.showFavoriteInAppBar = false,
  });

  @override
  State<UserProductDetailPage> createState() => _UserProductDetailPageState();
}

class _UserProductDetailPageState extends State<UserProductDetailPage> {
  bool _isLoadingFavorite = false;
  final ProductService _productService = ProductService();

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  void _shareProduct(Product product) {
    Share.share(
      'Cek produk ini di Primez Sports!\n\n'
      '${product.name}\nHarga: ${Formatter.formatPrice(product.price)}',
    );
  }

  List<Widget> _buildAppBarActions(Product product) {
    if (widget.isAdmin) {
      return [
        IconButton(icon: const Icon(Icons.edit), tooltip: 'Edit Produk', onPressed: () {}),
        IconButton(icon: const Icon(Icons.delete), tooltip: 'Hapus Produk', onPressed: () {}),
      ];
    }
    if (widget.showFavoriteInAppBar) {
      return [
        FavoriteButton(product: product, size: 28, activeColor: Colors.red, inactiveColor: Colors.white),
        SizedBox(width: 8.w),
      ];
    }
    return [];
  }

  Widget _buildProductImage(Product product) {
    try {
      if (product.imageBase64 != null && product.imageBase64!.isNotEmpty) {
        final decodedBytes = base64Decode(product.imageBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.memory(decodedBytes, height: 250.h, width: double.infinity, fit: BoxFit.cover),
        );
      }
      if (product.imageUrl.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.network(
            product.imageUrl,
            height: 250.h,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 250.h,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null)),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
          ),
        );
      }
      return _buildPlaceholderImage();
    } catch (_) {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Image.asset('assets/images/no_image.png', height: 250.h, width: double.infinity, fit: BoxFit.cover),
    );
  }

  Widget _buildEmptyPurchaseOptions() {
    return Container(
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
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: _productService.getProductById(widget.product.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(title: const Text('Memuat...'), backgroundColor: const Color(0xFFE53E3E), foregroundColor: Colors.white),
            body: const Center(child: CircularProgressIndicator(color: Color(0xFFE53E3E))),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(snapshot.hasError ? 'Error' : 'Produk Tidak Ditemukan'), backgroundColor: const Color(0xFFE53E3E), foregroundColor: Colors.white),
            body: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(snapshot.hasError ? Icons.error_outline : Icons.shopping_bag_outlined, size: 64.sp, color: snapshot.hasError ? Colors.red : Colors.grey.shade400),
                SizedBox(height: 16.h),
                Text(
                  snapshot.hasError ? 'Terjadi kesalahan' : 'Produk tidak ditemukan',
                  style: snapshot.hasError
                      ? GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600)
                      : GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                if (snapshot.hasError)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text('${snapshot.error}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade600)),
                  ),
              ]),
            ),
          );
        }

        final product = snapshot.data!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFE53E3E),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: _buildAppBarActions(product),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImage(product),
                SizedBox(height: 16.h),
                ProductInfo(product: product, showDescription: false),
                SizedBox(height: 24.h),
                if (product.description.isNotEmpty) ...[
                  Text(
                    product.description,
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.inter(fontSize: 14.sp, height: 1.3, letterSpacing: 0, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 24.h),
                ],
                if (product.purchaseOptions.isNotEmpty)
                  PurchaseOptionsList(options: product.purchaseOptions)
                else
                  _buildEmptyPurchaseOptions(),
                SizedBox(height: 24.h),
                if (!widget.showFavoriteInAppBar)
                  Consumer<FavoriteProvider>(
                    builder: (context, favoriteProvider, _) {
                      final isFavorite = favoriteProvider.isFavorite(product.id);
                      return ActionButtons(
                        isFavorite: isFavorite,
                        isLoadingFavorite: _isLoadingFavorite,
                        onFavoriteTap: () => _toggleFavorite(context),
                        onShareTap: () => _shareProduct(product),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
