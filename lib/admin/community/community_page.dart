import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/admin/community/admin_community_chat_page.dart';
import 'package:my_app/theme/app_colors.dart';

class AdminCommunityPage extends StatefulWidget {
  const AdminCommunityPage({super.key});

  @override
  State<AdminCommunityPage> createState() => _AdminCommunityPageState();
}

class _AdminCommunityPageState extends State<AdminCommunityPage> {
  bool _isInitializing = false;
  bool _isInitialized = false;
  String? _errorMessage;

  final List<Map<String, String>> _brands = [
    {
      'name': 'Nike',
      'logo': 'assets/logo_nike.png',
      'description': 'Kumpulan Sepatu Brand Nike Official',
    },
    {
      'name': 'Jordan',
      'logo': 'assets/logo_jordan.png',
      'description': 'Kumpulan Sepatu Brand Jordan Official',
    },
    {
      'name': 'Adidas',
      'logo': 'assets/logo_adidas.png',
      'description': 'Kumpulan Sepatu Brand Adidas Official',
    },
    {
      'name': 'Under Armour',
      'logo': 'assets/logo_under_armour.png',
      'description': 'Kumpulan Sepatu Brand Under Armour Official',
    },
    {
      'name': 'Puma',
      'logo': 'assets/logo_puma.png',
      'description': 'Kumpulan Sepatu Brand Puma Official',
    },
    {
      'name': 'Mizuno',
      'logo': 'assets/logo_mizuno.png',
      'description': 'Kumpulan Sepatu Brand Mizuno Official',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    try {
      final communitiesSnapshot = await FirebaseFirestore.instance
          .collection('communities')
          .limit(1)
          .get();

      setState(() {
        _isInitialized = communitiesSnapshot.docs.isNotEmpty;
      });
    } catch (e) {
      debugPrint('❌ Error checking initialization: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _initializeCommunities() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var brand in _brands) {
        final existing = await FirebaseFirestore.instance
            .collection('communities')
            .where('brand', isEqualTo: brand['name'])
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          final docRef = FirebaseFirestore.instance.collection('communities').doc();
          batch.set(docRef, {
            'brand': brand['name'],
            'name': brand['description'],
            'description': 'Komunitas resmi untuk produk ${brand['name']}',
            'logoPath': brand['logo'],
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ Will create community: ${brand['name']}');
        } else {
          debugPrint('⚠️ Community ${brand['name']} already exists');
        }
      }

      await batch.commit();
      debugPrint('✅ Communities initialized successfully');

      setState(() {
        _isInitializing = false;
        _isInitialized = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Communities berhasil diinisialisasi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error initializing communities: $e');
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal inisialisasi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Admin Komunitas',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(),
          ),

          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              margin: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 12.sp, color: Colors.red.shade900),
                  ),
                ],
              ),
            ),
            
          Expanded(
            child: _isInitializing
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        SizedBox(height: 16.h),
                        Text(
                          'Menginisialisasi communities...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final Map<String, int> postCounts = {};
                      
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>?;
                          final brand = data?['brand'] as String?;
                          if (brand != null) {
                            postCounts[brand] = (postCounts[brand] ?? 0) + 1;
                          }
                        }
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _brands.length,
                        itemBuilder: (context, index) {
                          final brand = _brands[index];
                          final postCount = postCounts[brand['name']] ?? 0;

                          return _buildBrandCard(
                            brand['name']!,
                            brand['logo']!,
                            brand['description']!,
                            postCount,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCard(
    String brandName,
    String logoPath,
    String description,
    int postCount,
  ) {
    return Card(
      color: AppColors.secondary,
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminCommunityChatPage(brand: brandName),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Image.asset(
                    logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.store,
                        size: 28.sp,
                        color: Colors.grey.shade400,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          postCount == 0
                              ? 'Belum ada posting'
                              : '$postCount posting',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}