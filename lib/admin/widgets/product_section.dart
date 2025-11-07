import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/admin/widgets/product_item.dart';

class ProductSection extends StatelessWidget {
  final String title;
  final List<Product> products;
  final void Function(Product)? onEdit;
  final void Function(Product)? onDelete;
  final VoidCallback onViewAll;

  const ProductSection({
    super.key,
    required this.title,
    required this.products,
    required this.onEdit,
    required this.onDelete,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 210.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 120.w,
                child: ProductItem(product: products[index],
                onEdit: onEdit != null ? () => onEdit!(products[index]) : null,
                onDelete: onDelete != null ? () => onDelete!(products[index]) : null,
                showActions: onEdit != null || onDelete != null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
