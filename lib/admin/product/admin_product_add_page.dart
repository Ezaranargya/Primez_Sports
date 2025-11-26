import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/services/product_service.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/services/supabase_storage_service.dart';
import 'package:my_app/theme/app_colors.dart';

class AdminAddProductPage extends StatefulWidget {
  final Product? product;
  const AdminAddProductPage({super.key, this.product});

  @override
  State<AdminAddProductPage> createState() => _AdminAddProductPageState();
}

class _AdminAddProductPageState extends State<AdminAddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _service = ProductService();
  final NotificationService _notificationService = NotificationService();
  final SupabaseStorageService _storageService = SupabaseStorageService();

  final TextEditingController _title = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _mainPrice = TextEditingController();

  final List<Map<String, dynamic>> _purchaseOptions = [];
  
  File? _bannerFile;
  String? _bannerUrl;
  File? _imageFile;
  String? _imageUrl;
  
  bool _isUploading = false;

  static const List<String> _brands = [
    'Nike',
    'Adidas',
    'Puma',
    'Under Armour',
    'Jordan',
    'Mizuno'
  ];

  static const List<String> _categoriesMain = [
    'Basketball',
    'Soccer',
    'Volleyball'
  ];

  static const List<String> _categoriesSub = ['Trending', 'Terbaru'];

  String? _selectedBrand;
  String? _selectedCategory1;
  String? _selectedCategory2;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _title.text = p.name;
      _desc.text = p.description;
      _mainPrice.text = p.price.toString();
      _imageUrl = p.imageUrl;
      _bannerUrl = p.bannerUrl;
      _selectedBrand = _brands.contains(p.brand) ? p.brand : null;
      _selectedCategory1 = _categoriesMain.contains(p.category) ? p.category : null;
      _selectedCategory2 = _categoriesSub.contains(p.subCategory) ? p.subCategory : null;

      _purchaseOptions.addAll(p.purchaseOptions.map((e) => {
            'link': TextEditingController(text: e.link),
            'price': TextEditingController(text: e.price.toString()),
            'logo': e.logoUrl,
          }));
    }

    if (_purchaseOptions.isEmpty) {
      _purchaseOptions.add({
        'link': TextEditingController(),
        'price': TextEditingController(),
        'logo': '',
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _mainPrice.dispose();
    for (final item in _purchaseOptions) {
      (item['link'] as TextEditingController).dispose();
      (item['price'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  String _getLogoFromUrl(String url, {String? brand}) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      if (host.contains('shopee')) return 'assets/logo_shopee.png';
      if (host.contains('tokopedia')) return 'assets/logo_tokopedia.png';
      if (host.contains('blibli')) return 'assets/logo_blibli.jpg';
      if (host.contains('nike')) return 'assets/logo_nike.png';
      if (host.contains('adidas')) return 'assets/logo_adidas.png';
      if (host.contains('puma')) return 'assets/logo_puma.png';
      if (host.contains('underarmour') || host.contains('under-armour')) {
        return 'assets/logo_under_armour.png';
      }
      if (host.contains('jordan')) return 'assets/logo_jordan.png';
      if (host.contains('mizuno')) return 'assets/logo_mizuno.png';
    }

    if (brand != null) {
      switch (brand.toLowerCase()) {
        case 'nike': return 'assets/logo_nike.png';
        case 'adidas': return 'assets/logo_adidas.png';
        case 'puma': return 'assets/logo_puma.png';
        case 'under armour': return 'assets/logo_under_armour.png';
        case 'jordan': return 'assets/logo_jordan.png';
        case 'mizuno': return 'assets/logo_mizuno.png';
      }
    }
    return '';
  }

  String _detectStoreNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      if (host.contains('shopee')) return 'Shopee';
      if (host.contains('tokopedia')) return 'Tokopedia';
      if (host.contains('blibli')) return 'Blibli';
      if (host.contains('nike')) return 'Nike Official';
      if (host.contains('adidas')) return 'Adidas Official';
      if (host.contains('puma')) return 'Puma Official';
      if (host.contains('underarmour') || host.contains('under-armour')) {
        return 'Under Armour Official';
      }
      if (host.contains('jordan')) return 'Jordan Official';
      if (host.contains('mizuno')) return 'Mizuno Official';
    }
    return 'Other';
  }

  Future<void> _pickBannerImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (picked == null) return;

      setState(() {
        _bannerFile = File(picked.path);
      });

      debugPrint('✅ Banner image selected');
    } catch (e) {
      debugPrint('❌ Error picking banner image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih banner: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
      });

      debugPrint('✅ Main image selected');
    } catch (e) {
      debugPrint('❌ Error picking main image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<String?> _getOrCreateCommunity(String brand) async {
    try {
      final communityQuery = await FirebaseFirestore.instance
          .collection('communities')
          .where('brand', isEqualTo: brand)
          .limit(1)
          .get();

      if (communityQuery.docs.isNotEmpty) {
        return communityQuery.docs.first.id;
      }

      final newCommunity = await FirebaseFirestore.instance
          .collection('communities')
          .add({
        'brand': brand,
        'name': 'Kumpulan Brand $brand Official',
        'description': 'Komunitas resmi untuk produk $brand',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Created new community for $brand: ${newCommunity.id}');
      return newCommunity.id;
    } catch (e) {
      debugPrint('❌ Error getting/creating community: $e');
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User belum login')),
      );
      return;
    }

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supabase user not authenticated')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? finalImageUrl = _imageUrl;
      String? finalBannerUrl = _bannerUrl;

      if (_imageFile != null) {
        debugPrint('📤 Uploading main image to Supabase...');
        
        if (_imageUrl != null && _imageUrl!.startsWith('http')) {
          await _storageService.deleteImage(_imageUrl!);
        }

        finalImageUrl = await _storageService.uploadImage(
          file: _imageFile!,
          bucket: 'product-images',
          folder: 'main',
          userId: supabaseUser.id,
        );

        if (finalImageUrl == null) {
          throw Exception('Gagal upload gambar utama');
        }

        debugPrint('✅ Main image uploaded: $finalImageUrl');
      }

      if (_bannerFile != null) {
        debugPrint('📤 Uploading banner image to Supabase...');
        
        if (_bannerUrl != null && _bannerUrl!.startsWith('http')) {
          await _storageService.deleteImage(_bannerUrl!);
        }

        finalBannerUrl = await _storageService.uploadImage(
          file: _bannerFile!,
          bucket: 'product-images',
          folder: 'banners',
          userId: supabaseUser.id,
        );

        if (finalBannerUrl == null) {
          throw Exception('Gagal upload banner');
        }

        debugPrint('✅ Banner uploaded: $finalBannerUrl');
      }

      final purchaseOptions = _purchaseOptions
          .where((item) =>
              (item['link'] as TextEditingController).text.trim().isNotEmpty)
          .map((item) {
        final link = (item['link'] as TextEditingController).text.trim();
        final price =
            double.tryParse((item['price'] as TextEditingController).text) ?? 0;
        return PurchaseOption(
          name: 'Link',
          storeName: _detectStoreNameFromUrl(link),
          price: price,
          logoUrl: _getLogoFromUrl(link, brand: _selectedBrand),
          link: link,
        );
      }).toList();

      final categoriesList = <String>[];
      if (_selectedCategory1 != null && _selectedCategory1!.isNotEmpty) {
        categoriesList.add(_selectedCategory1!);
      }
      if (_selectedCategory2 != null && _selectedCategory2!.isNotEmpty) {
        categoriesList.add(_selectedCategory2!);
      }

      final productName = _title.text.trim();
      final brandName = _selectedBrand ?? '';
      final isNewProduct = widget.product == null;

      final product = Product(
        id: widget.product?.id ?? '',
        name: productName,
        brand: brandName,
        description: _desc.text.trim(),
        price: double.tryParse(_mainPrice.text) ?? 0,
        categories: categoriesList,
        imageUrl: finalImageUrl ?? '',
        bannerUrl: finalBannerUrl ?? '',
        userId: user.uid,
        purchaseOptions: purchaseOptions,
      );

      debugPrint('🛒 [DEBUG] Product Data:');
      debugPrint('Nama: ${product.name}');
      debugPrint('Brand: ${product.brand}');
      debugPrint('Image URL: ${finalImageUrl ?? "empty"}');
      debugPrint('Banner URL: ${finalBannerUrl ?? "empty"}');

      bool success = false;
      String? savedProductId;

      if (isNewProduct) {
        savedProductId = await _service.addProductWithNotifications(product);
        success = savedProductId != null;
        
        if (success) {
          debugPrint('✅ New product added with ID: $savedProductId');
          
          try {
            await _notificationService.sendNotificationToAllUsers(
              title: "🎉 Produk Baru!",
              message: "$productName dari $brandName baru saja hadir!",
              imageUrl: finalImageUrl ?? "",
              brand: brandName,
              type: "product",
              productId: savedProductId,
              categories: categoriesList,
            );
            debugPrint('✅ Notification sent to all users');
          } catch (notifError) {
            debugPrint('⚠️ Product saved but notification failed: $notifError');
          }
        }
      } else {
        success = await _service.saveOrUpdateProduct(
          productId: widget.product?.id,
          product: product,
        );
        
        if (success) {
          debugPrint('✅ Product updated successfully');
          
          try {
            await _notificationService.sendGlobalNotification(
              title: "📢 Update Produk",
              message: "$productName telah diperbarui!",
              imageUrl: finalImageUrl ?? "",
              brand: brandName,
              type: "product",
              productId: widget.product?.id ?? "",
            );
            debugPrint('✅ Update notification created');
          } catch (notifError) {
            debugPrint('⚠️ Product updated but notification failed: $notifError');
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (isNewProduct
                  ? '✅ Produk berhasil ditambahkan!'
                  : '✅ Perubahan berhasil disimpan!')
              : '❌ Gagal menyimpan produk!'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      debugPrint('❌ Error saving product: $e');
      debugPrint(stack.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Produk' : 'Upload Produk',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengupload gambar ke Supabase...'),
                  SizedBox(height: 8),
                  Text(
                    'Mohon tunggu',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 700.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 200.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                                  )
                                : (_imageUrl != null && _imageUrl!.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12.r),
                                        child: Image.network(
                                          _imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.broken_image,
                                                    size: 40, color: Colors.red),
                                                SizedBox(height: 8.h),
                                                const Text('Error loading image',
                                                    style: TextStyle(color: Colors.red)),
                                              ],
                                            );
                                          },
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.image_outlined,
                                              size: 40, color: Colors.grey),
                                          SizedBox(height: 8.h),
                                          Text('Pilih Foto Produk',
                                              style: TextStyle(color: Colors.grey[600])),
                                        ],
                                      ),
                          ),
                        ),

                        SizedBox(height: 24.h),
                        
                        GestureDetector(
                          onTap: _pickBannerImage,
                          child: Container(
                            height: 140.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: _bannerFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Image.file(_bannerFile!, fit: BoxFit.cover),
                                  )
                                : (_bannerUrl != null && _bannerUrl!.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12.r),
                                        child: Image.network(
                                          _bannerUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.broken_image,
                                                    size: 36, color: Colors.red),
                                                SizedBox(height: 8.h),
                                                const Text('Error loading banner',
                                                    style: TextStyle(color: Colors.red)),
                                              ],
                                            );
                                          },
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.image_outlined,
                                              size: 36, color: Colors.grey),
                                          SizedBox(height: 8.h),
                                          Text(
                                            'Pilih Banner Produk',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                          ),
                        ),

                        SizedBox(height: 24.h),
                        TextFormField(
                          controller: _title,
                          decoration: _inputDecoration('Judul'),
                          validator: (v) => v!.isEmpty ? 'Judul wajib diisi' : null,
                          style: const TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 14.h),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Brand'),
                          value: _selectedBrand,
                          items: _brands
                              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedBrand = v),
                          validator: (v) => v == null ? 'Pilih brand' : null,
                          style: const TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 14.h),
                        TextFormField(
                          controller: _desc,
                          decoration: _inputDecoration('Deskripsi'),
                          maxLines: 3,
                          style: const TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 14.h),
                        TextFormField(
                          controller: _mainPrice,
                          decoration: _inputDecoration('Harga Produk Utama'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Harga wajib diisi' : null,
                          style: const TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: _inputDecoration('Kategori Utama'),
                                value: _selectedCategory1,
                                items: _categoriesMain
                                    .map((c) =>
                                        DropdownMenuItem(value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedCategory1 = v),
                                validator: (v) =>
                                    v == null ? 'Pilih kategori utama' : null,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: _inputDecoration('Sub Kategori'),
                                value: _selectedCategory2,
                                items: _categoriesSub
                                    .map((c) =>
                                        DropdownMenuItem(value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedCategory2 = v),
                                validator: (v) =>
                                    v == null ? 'Pilih sub kategori' : null,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Opsi Pembelian:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _purchaseOptions.add({
                                    'link': TextEditingController(),
                                    'price': TextEditingController(),
                                    'logo': '',
                                  });
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah'),
                            ),
                          ],
                        ),
                        ..._purchaseOptions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final linkController = item['link'] as TextEditingController;
                          final priceController = item['price'] as TextEditingController;
                          final logo = item['logo'] as String?;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Row(
                              children: [
                                if (logo != null && logo.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(right: 8.w),
                                    child: Image.asset(logo,
                                        width: 32.w,
                                        height: 32.w,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.store, 
                                              size: 32.sp, 
                                              color: Colors.grey);
                                        }),
                                  ),
                                Expanded(
                                  child: TextFormField(
                                    controller: linkController,
                                    decoration: _inputDecoration('Link ${index + 1}'),
                                    style: const TextStyle(color: Colors.black),
                                    onChanged: (v) {
                                      setState(() {
                                        item['logo'] = _getLogoFromUrl(v,
                                            brand: _selectedBrand);
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: TextFormField(
                                    controller: priceController,
                                    decoration: _inputDecoration('Harga'),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      linkController.dispose();
                                      priceController.dispose();
                                      _purchaseOptions.removeAt(index);
                                      if (_purchaseOptions.isEmpty) {
                                        _purchaseOptions.add({
                                          'link': TextEditingController(),
                                          'price': TextEditingController(),
                                          'logo': '',
                                        });
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        SizedBox(height: 32.h),

                        ElevatedButton(
                          onPressed: _saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                                vertical: 16.h, horizontal: 40.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            isEdit ? 'Simpan Perubahan' : 'Upload Produk',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}