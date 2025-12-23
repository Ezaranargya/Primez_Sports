import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/admin/news/admin_news_form_page.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';

class AdminNewsPage extends StatefulWidget {
  const AdminNewsPage({super.key});

  @override
  State<AdminNewsPage> createState() => _AdminNewsPageState();
}

class _AdminNewsPageState extends State<AdminNewsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteNews(String newsId) async {
    try {
      await _firestore.collection('news').doc(newsId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berita berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(String newsId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus berita "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNews(newsId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _navigateToForm({NewsModel? news}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminNewsFormPage(news: news),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Admin News',
          style: TextStyle(
            color: AppColors.backgroundColor,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(child: _buildNewsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add,color: AppColors.secondary),
        label: const Text(
          'Tambah Berita',
          style: TextStyle(fontFamily: 'Poppins',color: AppColors.secondary),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari berita...',
          hintStyle: const TextStyle(fontFamily: 'Poppins'),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All','Trending', 'Terbaru'];
    
    return Container(
      height: 50.h,
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('news').orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 80.sp, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  'Belum ada berita',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          );
        }

        final newsList = snapshot.data!.docs.map((doc) {
          return NewsModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        
        final filteredNews = newsList.where((news) {
          final matchesSearch = _searchQuery.isEmpty ||
              news.title.toLowerCase().contains(_searchQuery) ||
              news.subtitle.toLowerCase().contains(_searchQuery);
          
          final matchesCategory = _selectedCategory == 'All' ||
              news.categories.any((cat) => cat.toLowerCase() == _selectedCategory.toLowerCase());
          
          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredNews.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada berita yang sesuai',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: filteredNews.length,
          itemBuilder: (context, index) {
            final news = filteredNews[index];
            return _buildNewsCard(news);
          },
        );
      },
    );
  }

  Widget _buildNewsCard(NewsModel news) {
    final formatDate = DateFormat('dd MMM yyyy', 'id_ID');

    return Card(
      color: AppColors.secondary,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            child: _buildImage(news.imageUrl1),
          ),
          
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                if (news.categories.isNotEmpty)
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: news.categories.map((category) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                
                SizedBox(height: 8.h),
                
                
                Text(
                  news.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 6.h),
                
                
                if (news.subtitle.isNotEmpty)
                  Text(
                    news.subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: 'Poppins',
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                SizedBox(height: 8.h),
                
                
                // FIXED: Wrapped the Row in Flexible/Expanded to prevent overflow
                Row(
                  children: [
                    if (news.author.isNotEmpty) ...[
                      Icon(Icons.person_outline, size: 14.sp, color: Colors.grey[600]),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          news.author,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    Icon(Icons.calendar_today, size: 14.sp, color: Colors.grey[600]),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        formatDate.format(news.date),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToForm(news: news),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      onPressed: () => _confirmDelete(news.id, news.title),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
  return ProductImage(
    image: imagePath,
    width: double.infinity,
    height: 180.h,
    fit: BoxFit.contain,
    borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
  );
}

  Widget _placeholderImage() {
    return Container(
      height: 180.h,
      color: Colors.grey[300],
      child: Center(
        child: Icon(Icons.broken_image, size: 50.sp, color: Colors.grey),
      ),
    );
  }
}