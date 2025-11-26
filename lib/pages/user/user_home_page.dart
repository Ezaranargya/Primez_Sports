import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/services/product_service.dart';
import 'package:my_app/services/community_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/pages/user/home_content_page.dart';
import 'package:my_app/pages/product/product_detail_page.dart';
import 'package:my_app/pages/favorite/favorite_page.dart';
import 'package:my_app/pages/community/community_page.dart';
import 'package:my_app/pages/news/news_page.dart';
import 'package:my_app/pages/profile/profile_page.dart';
import 'package:my_app/providers/favorite_provider.dart';
import 'package:my_app/pages/user/widgets/logo_card.dart';
import 'package:my_app/brand_page.dart';
import 'dart:async';
import 'package:my_app/theme/app_colors.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final ProductService _productService = ProductService();
  final CommunityService _communityService = CommunityService();
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().loadFavorites();
    });
  }

  Stream<int> _getUnreadCommunityCountStream() {
    final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      print('⚠️ No user logged in for community count');
      return Stream.value(0);
    }

    print('📡 Setting up community count stream for userId: $userId');

    return FirebaseFirestore.instance
        .collection('community_posts')
        .snapshots()
        .asyncMap((postsSnapshot) async {
      try {
        final readBrandsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('readCommunityBrands')
            .get();

        final readBrands = readBrandsSnapshot.docs.map((doc) => doc.id).toSet();

        print('📚 User has read brands: $readBrands');

        final Map<String, int> brandPostCounts = {};
        for (var doc in postsSnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final brand = data['brand'] as String?;

            if (brand != null && brand.isNotEmpty) {
              brandPostCounts[brand] = (brandPostCounts[brand] ?? 0) + 1;
            }
          } catch (e) {
            print('❌ Error processing post ${doc.id}: $e');
            continue;
          }
        }

        print('📊 Brand post counts: $brandPostCounts');

        int unreadCount = 0;
        for (var brand in brandPostCounts.keys) {
          if (!readBrands.contains(brand)) {
            unreadCount++;
            print('🔔 Unread brand: $brand (${brandPostCounts[brand]} posts)');
          }
        }

        print('🔢 Final Community Unread Count: $unreadCount');
        return unreadCount;
      } catch (e) {
        print('❌ Error in community unread count calculation: $e');
        return 0;
      }
    });
  }

  Stream<int> _getUnreadNewsCountStream() {
    final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      print('⚠️ No user logged in for news count');
      return Stream.value(0);
    }

    print('📡 Setting up news count stream for userId: $userId');

    return FirebaseFirestore.instance
        .collection('news')
        .snapshots()
        .asyncMap((newsSnapshot) async {
      try {
        final userReadNewsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('readNews')
            .get();

        final userReadNewsIds =
            userReadNewsSnapshot.docs.map((doc) => doc.id).toSet();

        int unreadCount = 0;

        print('📊 Processing ${newsSnapshot.docs.length} news documents');
        print(
            '📚 User has read ${userReadNewsIds.length} news (from user collection)');

        for (var doc in newsSnapshot.docs) {
          try {
            final newsId = doc.id;
            final data = doc.data() as Map<String, dynamic>;

            List<String> readByList = [];
            if (data.containsKey('readBy') && data['readBy'] != null) {
              final readByField = data['readBy'];
              if (readByField is List) {
                for (var item in readByField) {
                  if (item != null) {
                    readByList.add(item.toString());
                  }
                }
              }
            }

            final isReadFromNewsDoc = readByList.contains(userId);
            final isReadFromUserDoc = userReadNewsIds.contains(newsId);

            final isRead = isReadFromNewsDoc || isReadFromUserDoc;

            if (!isRead) {
              unreadCount++;
            }

            print(
                '📰 $newsId: newsDoc=$isReadFromNewsDoc, userDoc=$isReadFromUserDoc, isRead=$isRead');
          } catch (e) {
            print('❌ Error processing news ${doc.id}: $e');
            continue;
          }
        }

        print('🔢 Final Unread Count: $unreadCount');
        return unreadCount;
      } catch (e) {
        print('❌ Error in unread count calculation: $e');
        return 0;
      }
    });
  }

  List<Widget> _pages(List<Product> allProducts) {
    return [
      HomeContentPage(allProducts: allProducts),
      const UserFavoritesPage(),
      const UserCommunityPage(),
      const UserNewsPage(),
      const UserProfilePage(),
    ];
  }

  void onItemTapped(int index) {
    setState(() => selectedIndex = index);

    if (index == 2) {
      _communityService.markCommunityAsVisited();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Product>>(
        stream: _productService.getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('⚠️ Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    'Terjadi Kesalahan',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allProducts = snapshot.data ?? [];

          if (allProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'Belum Ada Produk',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Produk akan muncul di sini',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return IndexedStack(
            index: selectedIndex,
            children: _pages(allProducts),
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: _communityService.getUnreadPostsCountStream(),  
        builder: (context, communitySnapshot) {
          int communityUnreadCount = 0;

          if (communitySnapshot.hasData) {
            communityUnreadCount = communitySnapshot.data!;
            print('🔔 Community Badge Update - Unread: $communityUnreadCount');
          } else if (communitySnapshot.hasError) {
            print('❌ Community Stream Error: ${communitySnapshot.error}');
            communityUnreadCount = 0;
          } else if (communitySnapshot.connectionState ==
              ConnectionState.waiting) {
            print('⏳ Community stream waiting...');
            communityUnreadCount = 0;
          }

          return StreamBuilder<int>(
            stream: _getUnreadNewsCountStream(),
            builder: (context, newsSnapshot) {
              int newsUnreadCount = 0;

              if (newsSnapshot.hasData) {
                newsUnreadCount = newsSnapshot.data!;
                print('🔔 Badge Update - News Unread: $newsUnreadCount');
              } else if (newsSnapshot.hasError) {
                print('❌ News Stream Error: ${newsSnapshot.error}');
                newsUnreadCount = 0;
              } else if (newsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                print('⏳ News stream waiting...');
                newsUnreadCount = 0;
              }

              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Colors.grey,
                currentIndex: selectedIndex,
                onTap: onItemTapped,
                selectedFontSize: 12.sp,
                unselectedFontSize: 12.sp,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_outline),
                    activeIcon: Icon(Icons.favorite),
                    label: 'Favorite',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildBadgeIcon(
                      Icons.chat_bubble_outline,
                      communityUnreadCount,
                    ),
                    activeIcon: _buildBadgeIcon(
                      Icons.chat_bubble,
                      communityUnreadCount,
                    ),
                    label: 'Komunitas',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildBadgeIcon(
                      Icons.newspaper_outlined,
                      newsUnreadCount,
                    ),
                    activeIcon: _buildBadgeIcon(
                      Icons.newspaper,
                      newsUnreadCount,
                    ),
                    label: 'Berita',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
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
    );
  }
}

class UserProductListPage extends StatefulWidget {
  const UserProductListPage({super.key});

  @override
  State<UserProductListPage> createState() => _UserProductListPageState();
}

class _UserProductListPageState extends State<UserProductListPage> {
  final ProductService _productService = ProductService();
  String selectedCategory = 'all';
  final List<String> categories = ['all', 'Basketball', 'Soccer', 'Volleyball'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Produk'),
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(firebase_auth.FirebaseAuth.instance.currentUser?.uid)
                .collection('notifications')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      context.go('/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
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
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ChoiceChip(
                    label: Text(
                      category == 'all' ? 'Semua' : category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13.sp,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedCategory = category);
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: Colors.grey[200],
                    elevation: isSelected ? 2 : 0,
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: selectedCategory == 'all'
            ? _productService.getAllProducts()
            : _productService.getProductsByCategory(selectedCategory),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('⚠️ Error: ${snapshot.error}');
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    'Terjadi Kesalahan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'Tidak ada produk',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    selectedCategory == 'all'
                        ? 'Belum ada produk tersedia'
                        : 'Tidak ada produk dalam kategori ini',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProductDetailPage(
                          product: product,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  width: 80.w,
                                  height: 80.w,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      width: 80.w,
                                      height: 80.w,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: progress.expectedTotalBytes !=
                                                  null
                                              ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80.w,
                                    height: 80.w,
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image_not_supported,
                                        size: 32.sp, color: Colors.grey[400]),
                                  ),
                                )
                              : Container(
                                  width: 80.w,
                                  height: 80.w,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image,
                                      size: 32.sp, color: Colors.grey[400]),
                                ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                product.brand,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              if (product.purchaseOptions.isNotEmpty)
                                Text(
                                  product.purchaseOptions.first.formattedPrice,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 24.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}