import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<Map<String, String>> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
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
                    bool hasUnread = false;
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      hasUnread = true;
                    }

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

          const SizedBox(height: 8),
          Container(
            decoration: const BoxDecoration(color: Color(0xFFE53E3E)),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 2),
            child: Row(
              children: List.generate(categories.length, (index) {
                final category = categories[index];
                final isSelected = selectedCategory == category["filter"];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onCategorySelected(category["filter"]!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        category["display"]!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          color: isSelected ? Colors.yellow : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                          fontFamily: "Poppins",
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
