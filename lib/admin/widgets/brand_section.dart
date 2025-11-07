import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/brand_page.dart';

class BrandSection extends StatelessWidget {
  const BrandSection({super.key});

  final List<Map<String, dynamic>> brands = const [
    {"name": "Nike", "icon": Icons.directions_run},
    {"name": "Adidas", "icon": Icons.sports_soccer},
    {"name": "Puma", "icon": Icons.sports_basketball},
    {"name": "Reebok", "icon": Icons.sports_handball},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Brand Pilihan",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => BrandPage(
                        brandName: "",
                        brandLogo: "",
                        products: const[],
                      )
                      ));
                },
                child: Text(
                  "Lihat Semua",
                  style: TextStyle(
                    color: const Color(0xFFE53E3E),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 80.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Padding(
                padding: EdgeInsets.only(left: 12.w),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28.r,
                      backgroundColor: Colors.grey[200],
                      child: Icon(
                        brand["icon"],
                        color: const Color(0xFFE53E3E),
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      brand["name"],
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
