import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminHeader extends StatelessWidget {
  final List<Map<String, String>> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final Function(String) onSearchChanged;

  const AdminHeader({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Cari produk...",
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[600],
                          size: 20.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 16.w,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none),
                    color: Colors.black87,
                    iconSize: 22.sp,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak ada notifikasi')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),
          Container(
            decoration: const BoxDecoration(color: Color(0xFFE53E3E)),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: SizedBox(
              height: 40.h,
              child: Row(
                children: List.generate(categories.length, (index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category["filter"];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final newValue = selectedCategory == category["filter"]
                            ? ""
                            : category["filter"]!;
                        onCategorySelected(newValue);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          category["display"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.yellow : Colors.white,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13.sp,
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}