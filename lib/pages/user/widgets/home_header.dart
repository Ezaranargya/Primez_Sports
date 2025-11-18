import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/pages/product/category_products_page.dart';
import 'package:my_app/models/product_model.dart';
import 'package:go_router/go_router.dart';

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
        .where((p) => p.categories.any(
            (c) => c.toLowerCase().contains(selected.toLowerCase())))
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

  Stream<int> _getUnreadNotificationsCount(String userId) {
    final personalStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();

    final readGlobalStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('readGlobalNotifications')
        .snapshots();

    return personalStream.asyncMap((personalSnapshot) async {
      try {
        final personalUnreadCount = personalSnapshot.docs.length;
        
        print('🔍 [Badge] Personal unread: $personalUnreadCount');
        
        final readGlobalSnapshot = await readGlobalStream.first
            .timeout(const Duration(seconds: 3))
            .catchError((e) {
              print('⚠️ Error getting readGlobalNotifications: $e');
              return null as QuerySnapshot<Map<String, dynamic>>;
            });

        final readGlobalIds = readGlobalSnapshot?.docs.map((doc) => doc.id).toSet() ?? {};
        
        print('🔍 [Badge] Read global IDs (${readGlobalIds.length}): $readGlobalIds');
        
        final globalSnapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .get()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('⏱️ Global notifications timeout');
                return null as QuerySnapshot<Map<String, dynamic>>;
              },
            );

        if (globalSnapshot == null) {
          print('📊 Badge count (personal only): $personalUnreadCount');
          return personalUnreadCount;
        }

        print('🔍 [Badge] Total global notifications: ${globalSnapshot.docs.length}');

        int globalUnreadCount = 0;
        for (var doc in globalSnapshot.docs) {
          if (!readGlobalIds.contains(doc.id)) {
            globalUnreadCount++;
            print('🔔 [Badge] Unread global: ${doc.id}');
          } else {
            print('✅ [Badge] Already read: ${doc.id}');
          }
        }

        final totalCount = personalUnreadCount + globalUnreadCount;
        print('📊 Badge count - Personal: $personalUnreadCount, Global: $globalUnreadCount, Total: $totalCount');
        
        return totalCount;
      } catch (e) {
        print('❌ Error calculating badge count: $e');
        return personalSnapshot.docs.length; 
      }
    }).handleError((error) {
      print('❌ Badge stream error: $error');
      return 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final userId = authSnapshot.data?.uid;

        return Container(
          width: double.infinity,
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      if (userId != null)
                        StreamBuilder<int>(
                          stream: _getUnreadNotificationsCount(userId),
                          builder: (context, snapshot) {
                            final unreadCount = snapshot.data ?? 0;
                            
                            if (snapshot.hasData) {
                              print('🔔 Badge UI Update: $unreadCount');
                            }
                            
                            return SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Material(
                                    shape: const CircleBorder(),
                                    color: Colors.grey[50],
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () =>
                                          context.push('/notifications'),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(Icons.notifications_none,
                                            size: 28),
                                      ),
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          unreadCount > 9
                                              ? '9+'
                                              : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        )
                      else
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
                              context.push('/notifications');
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xFFE53E3E)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _onCategoryTap(context, fixedCategories[0]),
                        child: Text(
                          fixedCategories[0]["display"]!,
                          style: TextStyle(
                            color: selectedCategory ==
                                    fixedCategories[0]["filter"]
                                ? Colors.yellow
                                : Colors.white,
                            fontWeight: selectedCategory ==
                                    fixedCategories[0]["filter"]
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
                            color: selectedCategory ==
                                    fixedCategories[1]["filter"]
                                ? Colors.yellow
                                : Colors.white,
                            fontWeight: selectedCategory ==
                                    fixedCategories[1]["filter"]
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
                            color: selectedCategory ==
                                    fixedCategories[2]["filter"]
                                ? Colors.yellow
                                : Colors.white,
                            fontWeight: selectedCategory ==
                                    fixedCategories[2]["filter"]
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
      },
    );
  }
}