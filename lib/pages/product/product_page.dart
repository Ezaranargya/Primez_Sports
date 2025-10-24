import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/services/product_service.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/pages/user/widgets/product_card.dart';

class UserProductPage extends StatelessWidget {
  const UserProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Text(
              "Produk",
              style: TextStyle(
                fontSize: 18.sp,
                fontFamily: "Poppins",
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: StreamBuilder<List<Product>>(
            // ✅ FIXED: Gunakan ProductService untuk consistency
            stream: ProductService().getAllProducts(),
            builder: (context, snapshot) {
              print('📊 UserProductPage - State: ${snapshot.connectionState}');
              print('📊 Has Data: ${snapshot.hasData}, Length: ${snapshot.data?.length ?? 0}');

              // Error handling
              if (snapshot.hasError) {
                print('❌ Error: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                      SizedBox(height: 16.h),
                      Text(
                        "Terjadi kesalahan",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "${snapshot.error}",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Empty state
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 80.sp, color: Colors.grey.shade400),
                      SizedBox(height: 16.h),
                      Text(
                        "Belum ada produk",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Produk akan muncul di sini",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: "Poppins",
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ✅ Data berhasil dimuat
              final products = snapshot.data!;
              print('✅ Displaying ${products.length} products');

              // Display products in grid
              return RefreshIndicator(
                onRefresh: () async {
                  // Trigger rebuild
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: GridView.builder(
                  padding: EdgeInsets.all(12.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return ProductCard(
                      product: p,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProductDetailPage(product: p),
                          ),
                        );
                      },
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
}