import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/utils/formatter.dart';

class ProductInfo extends StatelessWidget {
  final Product product;
  final bool showDescription;

  const ProductInfo({
    super.key,
    required this.product,
    this.showDescription = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          Formatter.formatPrice(product.price),
          style: TextStyle(
            fontSize: 18.sp,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),

        if (showDescription && product.description.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Text(
            product.description,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.5,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
        ],
      ],
    );
  }
}