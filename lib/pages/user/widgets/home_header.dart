import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/pages/product/category_products_page.dart';
import 'package:my_app/models/product_model.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<Product> allProducts;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.allProducts = const [],
  });

    static const List<Map<String, String>> fixedCategories = [
    {"display": "Basketball shoes", "filter": "basketball"},
    {"display": "Soccer shoes", "filter": "soccer"},
    {"display": "Volleyball shoes", "filter": "volleyball"},
  ];

  void _onCategoryTap(BuildContext context, Map<String, String> category) {
    final selected = category["filter"]!;
    onCategorySelected(selected);
    
        final filtered = allProducts
        .where((p) => p.categories.any((c) =>
            c.toLowerCase().contains(selected.toLowerCase())))
        .toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsPage(
          category: category["display"]!,
          products: filtered,
        ),
      ),
    ).then((_) => onCategorySelected(''));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,       color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
                        Container(
              width: double.infinity,               color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Cari produk...",
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_none),
                              color: Colors.black87,
                              iconSize: 22,
                              onPressed: () {
                                Navigator.pushNamed(context, '/notifications');
                              },
                            ),
                          ),
                          if (hasUnread)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 10.w,
                                height: 10.w,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

                        Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Color(0xFFE53E3E)),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                                    GestureDetector(
                    onTap: () => _onCategoryTap(context, fixedCategories[0]),
                    child: Text(
                      fixedCategories[0]["display"]!,
                      style: TextStyle(
                        color: selectedCategory == fixedCategories[0]["filter"] 
                            ? Colors.yellow 
                            : Colors.white,
                        fontWeight: selectedCategory == fixedCategories[0]["filter"]
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 14,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                  
                                    GestureDetector(
                    onTap: () => _onCategoryTap(context, fixedCategories[1]),
                    child: Text(
                      fixedCategories[1]["display"]!,
                      style: TextStyle(
                        color: selectedCategory == fixedCategories[1]["filter"]
                            ? Colors.yellow
                            : Colors.white,
                        fontWeight: selectedCategory == fixedCategories[1]["filter"]
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 14,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                  
                                    GestureDetector(
                    onTap: () => _onCategoryTap(context, fixedCategories[2]),
                    child: Text(
                      fixedCategories[2]["display"]!,
                      style: TextStyle(
                        color: selectedCategory == fixedCategories[2]["filter"]
                            ? Colors.yellow
                            : Colors.white,
                        fontWeight: selectedCategory == fixedCategories[2]["filter"]
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 14,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}