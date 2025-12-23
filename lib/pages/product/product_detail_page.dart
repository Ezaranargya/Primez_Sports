import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; 
import 'package:url_launcher/url_launcher.dart';
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

  // ✅ Share hanya dengan custom scheme (langsung ke APK)
  void _shareProduct(Product product) {
    // Gunakan HTTPS link yang sudah ter-setup dengan App Links
    final appLink = 'https://primez-sportz-2025.web.app/product/${product.id}';
    
    Share.share(
      'Cek produk ini di Primez Sports!\n\n'
      '${product.name}\n'
      'Harga: ${Formatter.formatPrice(product.price)}\n\n'
      '🔗 Buka di sini: $appLink',
      subject: 'Produk Primez Sports',
    );
  }

  // ✅ Show share options - hanya HTTPS link
  void _showShareOptions(BuildContext context, Product product) {
    // HTTPS link (akan auto-open app karena App Links sudah approved)
    final appLink = 'https://primez-sportz-2025.web.app/product/${product.id}';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bagikan Produk',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            
            // App Link Section
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link, color: Colors.blue.shade700, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Link Produk',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: SelectableText(
                      appLink,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12.sp,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: appLink));
                      Navigator.pop(context);
                      _showSnackBar('Link berhasil disalin!');
                    },
                    icon: Icon(Icons.copy, size: 18.sp),
                    label: Text('Copy Link', style: GoogleFonts.inter(fontSize: 14.sp)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade700),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _shareProduct(product);
                    },
                    icon: Icon(Icons.share, size: 18.sp),
                    label: Text('Share', style: GoogleFonts.inter(fontSize: 14.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53E3E),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8.h),
            
            // Info Banner
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 16.sp, color: Colors.green.shade700),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Link ini akan otomatis membuka aplikasi jika sudah terinstall',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  // ✅ URL LAUNCHER (untuk purchase options)
  Future<void> _launchURL(String url) async {
    if (url.isEmpty) {
      _showSnackBar('Link tidak tersedia');
      return;
    }

    try {
      String cleanUrl = url.trim();
      
      debugPrint('🔗 Launching URL: $cleanUrl');
      
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final uri = Uri.parse(cleanUrl);
      
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw Exception('URL tidak valid');
      }

      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      if (!launched) {
        throw Exception('Tidak dapat membuka link');
      }

      debugPrint('✅ URL launched successfully');

    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tidak bisa membuka link',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Pastikan browser atau aplikasi tersedia',
                  style: GoogleFonts.inter(fontSize: 12.sp),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Salin Link',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                _showSnackBar('Link berhasil disalin!');
              },
            ),
          ),
        );
      }
    }
  }

  List<Widget> _buildAppBarActions(Product product) {
    if (widget.isAdmin) {
      return [
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
      ];
    }
    if (widget.showFavoriteInAppBar) {
      return [
        FavoriteButton(
          product: product,
          size: 28,
          activeColor: Colors.red,
          inactiveColor: Colors.white,
        ),
        SizedBox(width: 8.w),
      ];
    }
    return [];
  }

  void _handleBackButton(BuildContext context) {
    // ✅ Cek apakah bisa pop dulu
    if (context.canPop()) {
      // Jika bisa pop (ada halaman sebelumnya), pop normal
      context.pop();
    } else {
      // Jika tidak bisa pop (datang dari deep link), arahkan ke home
      context.go('/user-home');
    }
  }

  Widget _buildProductImage(Product product) {
    try {
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
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
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
      child: Image.asset(
        'assets/images/no_image.png',
        height: 250.h,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
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
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Wrap dengan WillPopScope untuk handle back button
    return WillPopScope(
      onWillPop: () async {
        // Cek apakah bisa pop (ada halaman sebelumnya di stack)
        if (context.canPop()) {
          // Jika bisa pop, biarkan pop normal
          return true;
        } else {
          // Jika tidak bisa pop (datang dari deep link), arahkan ke home
          context.go('/user-home');
          return false;
        }
      },
      child: StreamBuilder<Product?>(
        stream: _productService.getProductById(widget.product.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBackButton(context),
                ),
                title: const Text('Memuat...'),
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
              ),
              body: const Center(
                child: CircularProgressIndicator(color: Color(0xFFE53E3E)),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBackButton(context),
                ),
                title: Text(
                  snapshot.hasError ? 'Error' : 'Produk Tidak Ditemukan',
                ),
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      snapshot.hasError
                          ? Icons.error_outline
                          : Icons.shopping_bag_outlined,
                      size: 64.sp,
                      color: snapshot.hasError ? Colors.red : Colors.grey.shade400,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      snapshot.hasError
                          ? 'Terjadi kesalahan'
                          : 'Produk tidak ditemukan',
                      style: snapshot.hasError
                          ? GoogleFonts.poppins(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              )
                          : GoogleFonts.poppins(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                    ),
                    if (snapshot.hasError)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          final product = snapshot.data!;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBackButton(context),
                tooltip: 'Kembali',
              ),
              title: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 18.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Deskripsi Produk",
                            style: GoogleFonts.poppins(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            product.description.trim(),
                            textAlign: TextAlign.start,
                            textWidthBasis: TextWidthBasis.parent,
                            style: GoogleFonts.inter(
                              fontSize: 14.2.sp,
                              height: 1.75,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 26.h),
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
                          onShareTap: () => _showShareOptions(context, product),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}