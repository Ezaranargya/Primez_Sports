import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/brand_page.dart';

class BrandSection extends StatelessWidget {
  final List<Product> products;

  const BrandSection({
    super.key,
    required this.products,
  });

  static const List<Map<String, String>> _brands = [
    {"logo": "assets/logo_nike.png", "name": "Nike"},
    {"logo": "assets/logo_jordan.png", "name": "Jordan"},
    {"logo": "assets/logo_adidas.png", "name": "Adidas"},
    {"logo": "assets/logo_under_armour.png", "name": "Under Armour"},
    {"logo": "assets/logo_puma.png", "name": "Puma"},
    {"logo": "assets/logo_mizuno.png", "name": "Mizuno"},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            "Brand",
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.3,
            ),
            itemCount: _brands.length,
            itemBuilder: (context, index) {
              final brand = _brands[index];
              return _BrandCard(
                logoPath: brand["logo"]!,
                brandName: brand["name"]!,
                onTap: () => _navigateToBrand(context, brand),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToBrand(BuildContext context, Map<String, String> brand) {
    final brandProducts = products
        .where((p) => p.brand.toLowerCase() == brand["name"]!.toLowerCase())
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrandPage(
          brandName: brand["name"]!,
          brandLogo: brand["logo"]!,
          products: brandProducts,
        ),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final String logoPath;
  final String brandName;
  final VoidCallback onTap;

  const _BrandCard({
    required this.logoPath,
    required this.brandName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[350]!,
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.all(15.w),
                  child: Image.asset(
                    logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 32.sp,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              brandName,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12.r),
                  splashColor: Colors.black.withOpacity(0.05),
                  highlightColor: Colors.black.withOpacity(0.02),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
