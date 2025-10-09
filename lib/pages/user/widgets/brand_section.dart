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
    {
      "logo": "https://i.ibb.co.com/pjvscvQR/logo-nike.png",
      "name": "Nike"
    },
    {
      "logo": "https://i.ibb.co.com/zWkbN6gx/logo-jordan.png",
      "name": "Jordan"
    },
    {
      "logo": "https://i.ibb.co.com/8gP849Bm/logo-adidas.png",
      "name": "Adidas"
    },
    {
      "logo": "https://i.ibb.co.com/fGpWwGDP/logo-under-armour.png",
      "name": "Under Armour"
    },
    {
      "logo": "https://i.ibb.co.com/mrSH0jfT/logo-puma.png",
      "name": "Puma"
    },
    {
      "logo": "https://i.ibb.co.com/TqYxvdLR/logo-mizuno.png",
      "name": "Mizuno"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Brand",
          style: TextStyle(
            fontFamily: "Poppins",
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 79.w / 51.h,
          ),
          itemCount: _brands.length,
          itemBuilder: (context, index) {
            final brand = _brands[index];
            return _BrandCard(
              logoUrl: brand["logo"]!,
              brandName: brand["name"]!,
              onTap: () => _navigateToBrand(context, brand),
            );
          },
        ),
      ],
    );
  }

  void _navigateToBrand(BuildContext context, Map<String, String> brand) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrandPage(
          brandName: brand["name"]!,
          brandLogo: brand["logo"]!,
          products: products,
        ),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final String logoUrl;
  final String brandName;
  final VoidCallback onTap;

  const _BrandCard({
    required this.logoUrl,
    required this.brandName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 79.w,
        height: 51.h,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image,
              size: 40.sp,
              color: Colors.grey,
            );
          },
        ),
      ),
    );
  }
}