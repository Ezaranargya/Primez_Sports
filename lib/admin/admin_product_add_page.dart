import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/services/product_service.dart';
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

  final TextEditingController _title = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _mainPrice = TextEditingController();
  final List<Map<String, dynamic>> _purchaseOptions = [];

  File? _imageFile;
  String? _base64Image;

  // ✅ FIXED: List sebagai const untuk guarantee no duplicates
  static const List<String> _categoriesMain = ['Basketball', 'Soccer', 'Volleyball'];
  static const List<String> _categoriesSub = ['Trending', 'Terbaru'];
  static const List<String> _brands = ['Nike', 'Adidas', 'Puma', 'Under Armour', 'Jordan', 'Mizuno'];

  // ✅ FIXED: Initialize dengan value yang PASTI valid atau null
  String? _selectedBrand;
  String? _selectedCategory1;
  String? _selectedCategory2;

  @override
  void initState() {
    super.initState();
    print('🎬 AdminAddProductPage initState - isEdit: ${widget.product != null}');

    if (widget.product != null) {
      final p = widget.product!;
      print('📦 Loading product: ${p.name}');
      
      _title.text = p.name;
      _desc.text = p.description;
      _mainPrice.text = p.price.toString();
      _base64Image = p.imageBase64;

      // ✅ FIXED: Validate brand sebelum set
      if (p.brand.isNotEmpty && _brands.contains(p.brand)) {
        _selectedBrand = p.brand;
        print('✅ Brand loaded: $_selectedBrand');
      } else if (p.brand.isNotEmpty) {
        print('⚠️ Invalid brand: ${p.brand}, available: $_brands');
        _selectedBrand = null; // Set null jika tidak valid
      }

      // ✅ FIXED: Validate category sebelum set
      if (p.category.isNotEmpty && _categoriesMain.contains(p.category)) {
        _selectedCategory1 = p.category;
        print('✅ Category loaded: $_selectedCategory1');
      } else if (p.category.isNotEmpty) {
        print('⚠️ Invalid category: ${p.category}, available: $_categoriesMain');
        _selectedCategory1 = null;
      }

      // ✅ FIXED: Validate subCategory sebelum set
      if (p.subCategory.isNotEmpty && _categoriesSub.contains(p.subCategory)) {
        _selectedCategory2 = p.subCategory;
        print('✅ SubCategory loaded: $_selectedCategory2');
      } else if (p.subCategory.isNotEmpty) {
        print('⚠️ Invalid subCategory: ${p.subCategory}, available: $_categoriesSub');
        _selectedCategory2 = null;
      }

      // Load purchase options
      if (p.purchaseOptions.isNotEmpty) {
        _purchaseOptions.addAll(p.purchaseOptions.map((e) => {
              'link': TextEditingController(text: e.link),
              'price': TextEditingController(text: e.price.toString()),
              'logo': e.logoUrl,
            }));
        print('✅ Loaded ${p.purchaseOptions.length} purchase options');
      }
    }
    
    // Add default empty option if none exist
    if (_purchaseOptions.isEmpty) {
      _purchaseOptions.add({
        'link': TextEditingController(),
        'price': TextEditingController(),
        'logo': '',
      });
    }
    
    print('✅ initState completed');
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _mainPrice.dispose();
    for (var option in _purchaseOptions) {
      option['link']?.dispose();
      option['price']?.dispose();
    }
    super.dispose();
  }

  String _getLogoFromUrl(String url, {String? brand}) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      if (host.contains('shopee')) return 'assets/logo_shopee.png';
      if (host.contains('tokopedia')) return 'assets/logo_tokopedia.png';
      if (host.contains('blibli')) return 'assets/logo_blibli.png';
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageFile = File(picked.path);
          _base64Image = base64Encode(bytes);
        });
        print('✅ Image picked successfully');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      print('⚠️ Form validation failed');
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User belum login')),
      );
      return;
    }

    print('💾 Saving product...');

    final purchaseOptions = _purchaseOptions
        .where((item) => item['link']!.text.isNotEmpty)
        .map((item) {
      final link = item['link']!.text;
      return PurchaseOption(
        name: 'Link',
        storeName: 'Toko',
        price: double.tryParse(item['price']!.text) ?? 0,
        logoUrl: _getLogoFromUrl(link, brand: _selectedBrand),
        link: link,
      );
    }).toList();

    final newProduct = Product(
      id: widget.product?.id ?? '',
      name: _title.text.trim(),
      brand: _selectedBrand ?? '',
      description: _desc.text.trim(),
      price: double.tryParse(_mainPrice.text) ?? 0,
      category: _selectedCategory1 ?? '',
      subCategory: _selectedCategory2 ?? '',
      imageUrl: '',
      imageBase64: _base64Image ?? widget.product?.imageBase64 ?? '',
      bannerImage: '',
      userId: user.uid,
      categories: [
        if (_selectedCategory1 != null) _selectedCategory1!,
        if (_selectedCategory2 != null) _selectedCategory2!,
      ],
      purchaseOptions: purchaseOptions,
    );

    try {
      if (widget.product == null) {
        await _service.addProduct(newProduct);
        print('✅ Product added successfully');
      } else {
        await _service.updateProduct(widget.product!.id, newProduct);
        print('✅ Product updated successfully');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null
                ? 'Produk berhasil ditambahkan!'
                : 'Perubahan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // ✅ Return true untuk trigger refresh
      }
    } catch (e) {
      print('❌ Error saving product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    print('🎨 Building AdminAddProductPage - brand: $_selectedBrand, cat1: $_selectedCategory1, cat2: $_selectedCategory2');

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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // PICK IMAGE
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150.h,
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
                      : (_base64Image != null && _base64Image!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.memory(
                                base64Decode(_base64Image!),
                                fit: BoxFit.cover,
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
              SizedBox(height: 20.h),

              // TITLE
              TextFormField(
                controller: _title,
                decoration: _inputDecoration('Judul'),
                validator: (v) => v!.isEmpty ? 'Judul wajib diisi' : null,
                style: const TextStyle(color: Colors.black),
              ),
              SizedBox(height: 10.h),

              // ✅ BRAND DROPDOWN - FIXED
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Brand'),
                value: _selectedBrand,
                hint: const Text('Pilih Brand'),
                items: _brands.map((brand) {
                  return DropdownMenuItem<String>(
                    value: brand,
                    child: Text(brand),
                  );
                }).toList(),
                onChanged: (v) {
                  print('📝 Brand changed to: $v');
                  setState(() => _selectedBrand = v);
                },
                validator: (v) => v == null ? 'Pilih brand' : null,
                style: const TextStyle(color: Colors.black),
              ),
              SizedBox(height: 10.h),

              // DESCRIPTION
              TextFormField(
                controller: _desc,
                decoration: _inputDecoration('Deskripsi'),
                maxLines: 3,
                style: const TextStyle(color: Colors.black),
              ),
              SizedBox(height: 10.h),

              // MAIN PRICE
              TextFormField(
                controller: _mainPrice,
                decoration: _inputDecoration('Harga Produk Utama'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Harga wajib diisi';
                  if (double.tryParse(v) == null) return 'Harga harus berupa angka';
                  return null;
                },
                style: const TextStyle(color: Colors.black),
              ),
              SizedBox(height: 20.h),

              // CATEGORY ROW
              Row(
                children: [
                  // ✅ KATEGORI UTAMA DROPDOWN - FIXED
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Kategori Utama'),
                      value: _selectedCategory1,
                      hint: const Text('Pilih Kategori'),
                      items: _categoriesMain.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (v) {
                        print('📝 Category1 changed to: $v');
                        setState(() => _selectedCategory1 = v);
                      },
                      validator: (v) => v == null ? 'Pilih kategori utama' : null,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // ✅ SUB KATEGORI DROPDOWN - FIXED
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Sub Kategori'),
                      value: _selectedCategory2,
                      hint: const Text('Pilih Sub'),
                      items: _categoriesSub.map((sub) {
                        return DropdownMenuItem<String>(
                          value: sub,
                          child: Text(sub),
                        );
                      }).toList(),
                      onChanged: (v) {
                        print('📝 Category2 changed to: $v');
                        setState(() => _selectedCategory2 = v);
                      },
                      validator: (v) => v == null ? 'Pilih sub kategori' : null,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // PURCHASE OPTIONS
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Opsi pembelian:',
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
                          print('➕ Added purchase option, total: ${_purchaseOptions.length}');
                        },
                        icon: Icon(Icons.add, color: AppColors.primary),
                        label: const Text(''),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  ..._purchaseOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Row(
                        children: [
                          if (item['logo'] != null &&
                              (item['logo'] as String).isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: Image.asset(
                                item['logo'] as String,
                                width: 32.w,
                                height: 32.w,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox(),
                              ),
                            ),
                          Expanded(
                            child: TextFormField(
                              controller: item['link'],
                              decoration: _inputDecoration('Link ${index + 1}'),
                              style: const TextStyle(color: Colors.black),
                              onChanged: (v) {
                                setState(() {
                                  item['logo'] = _getLogoFromUrl(v, brand: _selectedBrand);
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: TextFormField(
                              controller: item['price'],
                              decoration: _inputDecoration('Harga'),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                item['link']?.dispose();
                                item['price']?.dispose();
                                _purchaseOptions.removeAt(index);
                              });
                              print('➖ Removed purchase option, total: ${_purchaseOptions.length}');
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              SizedBox(height: 20.h),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  onPressed: _saveProduct,
                  child: Text(
                    isEdit ? 'Simpan Perubahan' : 'Upload Produk',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}