import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/favorite/widgets/favorite_item_card.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/providers/favorite_provider.dart';

class UserFavoritePage extends StatefulWidget {
  const UserFavoritePage({super.key});

  @override
  State<UserFavoritePage> createState() => _UserFavoritePageState();
}

class _UserFavoritePageState extends State<UserFavoritePage> {
  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      extendBodyBehindAppBar: true, // biar header bisa nutup status bar
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            // 🔺 Header merah penuh sampai status bar
            Container(
              width: double.infinity,
              height: statusBarHeight + 60.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    offset: const Offset(0, 3),
                    blurRadius: 5,
                  ),
                ],
              ),
              padding: EdgeInsets.only(top: statusBarHeight),
              alignment: Alignment.center,
              child: Text(
                "Favorites",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  letterSpacing: 0.3,
                  fontFamily: "Poppins",
                ),
              ),
            ),

            // 🔹 Tambahkan jarak antara header dan daftar produk
            SizedBox(height: 12.h),

            // 🔻 Daftar produk favorit
            Expanded(
              child: Consumer<FavoriteProvider>(
                builder: (context, favoriteProvider, _) {
                  final favorites = favoriteProvider.favorites;

                  if (favorites.isEmpty) {
                    return _buildEmptyState("Belum ada produk favorite");
                  }

                  return ListView.builder(
                    key: const PageStorageKey('favoritesList'),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final Product product = favorites[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: FavoriteItemCard(product: product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 80.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontFamily: "Poppins",
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Mulai tambahkan produk favorit Anda!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontFamily: "Poppins",
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
