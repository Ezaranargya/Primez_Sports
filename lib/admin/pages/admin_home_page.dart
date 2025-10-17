import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/admin/widgets/header.dart';
import '../widgets/banner_widget.dart';
import '../widgets/product_section.dart';
import '../widgets/brand_section.dart';
import '../widgets/product_item.dart';
import '../dialogs/add_product_dialog.dart';
import '../dialogs/edit_product_dialog.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int selectedIndex = 0;
  String searchQuery = "";
  String selectedCategory = "";
  List<Product> products = [];

  final List<Map<String, String>> categories = [
    {"display": "Basketball", "filter": "basketball"},
    {"display": "Soccer", "filter": "soccer"},
    {"display": "Volleyball", "filter": "volleyball"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  List<Product> get filteredProducts {
    return products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory.isEmpty ||
          p.categories.map((e) => e.toLowerCase()).contains(selectedCategory.toLowerCase());
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Product> get trendingProducts {
    return products
        .where((p) => p.categories.map((e) => e.toLowerCase()).contains("trending"))
        .toList();
  }

  List<Product> get newProducts {
    return products
        .where((p) => p.categories.map((e) => e.toLowerCase()).contains("terbaru"))
        .toList();
  }

  void _showAddProductDialog() async {
    final newProduct = await showDialog<Product>(
      context: context,
      builder: (context) => const AddProductDialog(),
    );

    if (newProduct != null) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(newProduct.id)
          .set(newProduct.toMap());

      setState(() => products.add(newProduct));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _handleEditProduct(Product product, String section) async {
    final updatedProduct = await showDialog<Product>(
      context: context,
      builder: (context) => EditProductDialog(product: product),
    );

    if (updatedProduct != null) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .update(updatedProduct.toMap());

      setState(() {
        final index = products.indexWhere((p) => p.id == product.id);
        if (index != -1) products[index] = updatedProduct;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil diupdate'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  void _handleDeleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
      setState(() => products.removeWhere((p) => p.id == product.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} berhasil dihapus'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToViewAll(String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lihat semua $section')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE53E3E),
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(160.h),
        child: AdminHeader(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: (value) => setState(() => selectedCategory = value),
          onSearchChanged: (value) => setState(() => searchQuery = value),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BannerWidget(),
            SizedBox(height: 24.h),
            const BrandSection(),
            SizedBox(height: 24.h),

            if (trendingProducts.isNotEmpty) ...[
              ProductSection(
                title: "Trending",
                products: trendingProducts,
                onEdit: (product) => _handleEditProduct(product, "Trending"),
                onDelete: _handleDeleteProduct,
                onViewAll: () => _navigateToViewAll("Trending"),
              ),
              SizedBox(height: 24.h),
            ],

            if (newProducts.isNotEmpty) ...[
              ProductSection(
                title: "Terbaru",
                products: newProducts,
                onEdit: (product) => _handleEditProduct(product, "Terbaru"),
                onDelete: _handleDeleteProduct,
                onViewAll: () => _navigateToViewAll("Terbaru"),
              ),
              SizedBox(height: 24.h),
            ],

            Text(
              searchQuery.isNotEmpty || selectedCategory.isNotEmpty
                  ? "Hasil Pencarian (${filteredProducts.length})"
                  : "Semua Produk (${filteredProducts.length})",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: "Poppins",
              ),
            ),
            SizedBox(height: 16.h),

            filteredProducts.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "Tidak ada produk ditemukan",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.65,
                    ),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductItem(
                        product: product,
                        onEdit: () => _handleEditProduct(product, "All"),
                        onDelete: () => _handleDeleteProduct(product),
                        showActions: true,
                      );
                    },
                  ),

            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }
}
