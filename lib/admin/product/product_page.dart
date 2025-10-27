import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/services/product_service.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/admin/product/admin_product_add_page.dart';

class AdminProductPage extends StatefulWidget {
  const AdminProductPage({super.key});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  final ProductService _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: Text(
              'Kelola Produk',
              style: TextStyle(
                color: AppColors.backgroundColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: 25.h),
            child: FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () async {
                // ✅ Navigate dan tunggu result
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAddProductPage(),
                  ),
                );
                // ✅ Refresh jika ada perubahan
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              child: Icon(Icons.add, size: 24.sp, color: Colors.white),
            ),
          ),
          body: StreamBuilder<List<Product>>(
            stream: _productService.getAllProducts(),
            builder: (context, snapshot) {
              // Debug logging
              print('📊 Connection State: ${snapshot.connectionState}');
              print('📊 Has Data: ${snapshot.hasData}');
              print('📊 Data Length: ${snapshot.data?.length ?? 0}');
              
              if (snapshot.hasError) {
                print('❌ Error: ${snapshot.error}');
              }

              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error state
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                      SizedBox(height: 16.h),
                      Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(fontSize: 14.sp, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Retry
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              // Empty state
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64.sp, color: Colors.grey),
                      SizedBox(height: 16.h),
                      Text(
                        'Belum ada produk',
                        style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Tap tombol + untuk menambah produk',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // Product list
              final products = snapshot.data!;
              print('✅ Displaying ${products.length} products');
              
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // Force refresh
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(12.w),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return Card(
                      color: AppColors.backgroundColor,
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 6.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: _buildProductImage(p),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (p.brand.isNotEmpty)
                              Text(
                                p.brand,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Text(
                              p.formattedPrice,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (p.categories.isNotEmpty)
                              Text(
                                p.categories.join(' • '),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, size: 20.sp),
                              onPressed: () async {
                                // ✅ Navigate dan tunggu result
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AdminAddProductPage(product: p),
                                  ),
                                );
                                // ✅ Refresh jika ada perubahan
                                if (result == true && mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20.sp,
                              ),
                              onPressed: () => _confirmDelete(context, p),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _productService.deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Error deleting product: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildProductImage(Product product) {
    // ✅ PRIORITY 1: Check imageBase64 first (dari AdminAddProductPage)
    if (product.imageBase64 != null && product.imageBase64!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(product.imageBase64!),
          width: 50.w,
          height: 50.w,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            print('❌ Error decoding base64 image for ${product.id}');
            return _buildPlaceholder();
          },
        );
      } catch (e) {
        print('❌ Exception decoding base64: $e');
      }
    }

    // ✅ PRIORITY 2: Check imageUrl
    if (product.imageUrl.isNotEmpty) {
      // Local file path
      if (product.imageUrl.startsWith('/data')) {
        return Image.file(
          File(product.imageUrl),
          width: 50.w,
          height: 50.w,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }

      // Asset image
      if (product.imageUrl.startsWith('assets/')) {
        return Image.asset(
          product.imageUrl,
          width: 50.w,
          height: 50.w,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }

      // Network image
      return Image.network(
        product.imageUrl,
        width: 50.w,
        height: 50.w,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 50.w,
            height: 50.w,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // ✅ FALLBACK: No image available
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 50.w,
      height: 50.w,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_not_supported,
        size: 24.sp,
        color: Colors.grey[400],
      ),
    );
  }
}