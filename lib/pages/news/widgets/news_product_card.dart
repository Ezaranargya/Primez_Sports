import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/utils/formatter.dart';
import 'package:my_app/pages/product/widgets/product_image.dart'; // pastikan path sesuai

/// ============================================================
/// 🛍️ WIDGET: NewsProductCard
/// Card produk dengan gambar (Base64/URL/assets), nama, harga, dan brand.
/// ============================================================
class NewsProductCard extends StatelessWidget {
  final Product product;

  const NewsProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final String brand =
        product.brand.isNotEmpty ? product.brand : 'Unknown Brand';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProductDetailPage(product: product),
        ),
      ),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ============================================================
              /// 🖼️ Gambar Produk (otomatis deteksi Base64 / URL / Asset)
              /// ============================================================
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: ProductImage(
                  image: product.imageUrl,
                  width: 100.w,
                  height: 100.h,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12.w),

              /// ============================================================
              /// 📋 Detail Produk
              /// ============================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 Nama produk
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),

                    /// 🔹 Harga
                    Text(
                      Formatter.formatPrice(product.price),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 6.h),

                    /// 🔹 Brand
                    Row(
                      children: [
                        Icon(Icons.storefront,
                            size: 14.sp, color: Colors.grey[600]),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            brand,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
