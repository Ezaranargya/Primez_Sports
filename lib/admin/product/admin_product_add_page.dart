import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/services/product_service.dart';
import 'package:my_app/services/notification_service.dart';
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

  final TextEditingController _title = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _mainPrice = TextEditingController();

  final List<Map<String, dynamic>> _purchaseOptions = [];
  File? _bannerFile;
  String? _bannerBase64;
  File? _imageFile;
  String? _base64Image;

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
      _base64Image = p.imageBase64.isNotEmpty ? p.imageBase64 : null;
      _bannerBase64 = p.bannerImage.isNotEmpty ? p.bannerImage : null;
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
      if (host.contains('blibli')) return 'assets/logo_blibli.png';
      if (host.contains('nike')) return 'assets/logo_nike.png';
    }

    if (brand != null) {
      switch (brand.toLowerCase()) {
        case 'nike':
          return 'assets/logo_nike.png';
        case 'adidas':
          return 'assets/logo_adidas.png';
        case 'puma':
          return 'assets/logo_puma.png';
        case 'under armour':
          return 'assets/logo_under_armour.png';
        case 'jordan':
          return 'assets/logo_jordan.png';
        case 'mizuno':
          return 'assets/logo_mizuno.png';
      }
    }
    return '';
  }

  Future<void> _pickBannerImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final resized = img.copyResize(decoded, width: 1200);
        final compressed = img.encodeJpg(resized, quality: 85);
        final base64Image = base64Encode(compressed);

        setState(() {
          _bannerFile = File(picked.path);
          _bannerBase64 = base64Image;
        });

        print('✅ Banner converted to Base64 (${base64Image.length} chars)');
      }
    } catch (e) {
      print('❌ Error picking banner image: $e');
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
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final resized = img.copyResize(decoded, width: 800);
        final compressed = img.encodeJpg(resized, quality: 85);
        final base64Image = base64Encode(compressed);

        setState(() {
          _imageFile = File(picked.path);
          _base64Image = base64Image;
        });

        print(
            '✅ Gambar utama berhasil dikonversi ke Base64 (${base64Image.length} chars)');
      }
    } catch (e) {
      print('❌ Error picking main image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
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

    final purchaseOptions = _purchaseOptions
        .where((item) =>
            (item['link'] as TextEditingController).text.trim().isNotEmpty)
        .map((item) {
      final link = (item['link'] as TextEditingController).text.trim();
      final price =
          double.tryParse((item['price'] as TextEditingController).text) ?? 0;
      return PurchaseOption(
        name: 'Link',
        storeName: 'Toko',
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
      imageBase64: _base64Image ?? widget.product?.imageBase64 ?? '',
      bannerImage: _bannerBase64 ?? widget.product?.bannerImage ?? '',
      userId: user.uid,
      purchaseOptions: purchaseOptions,
    );

    print('🧾 [DEBUG] Product Data:');
    print('Nama: ${product.name}');
    print('Brand: ${product.brand}');
    print('Harga: ${product.price}');
    print('Categories: ${product.categories}');
    print('Jumlah opsi pembelian: ${product.purchaseOptions.length}');
    print(
        'Image Base64: ${_base64Image != null ? "✅ Ada (${_base64Image!.length} chars)" : "❌ Kosong"}');
    print(
        'Banner Base64: ${_bannerBase64 != null ? "✅ Ada (${_bannerBase64!.length} chars)" : "❌ Kosong"}');

    bool success = false;
    String? savedProductId;

    try {
      if (isNewProduct) {
        savedProductId = await _service.addProductWithNotifications(product);
        success = savedProductId != null;
        
        if (success) {
          print('✅ Produk baru berhasil ditambahkan dengan ID: $savedProductId');
          
          try {
            await _notificationService.sendNotificationToAllUsers(
              title: "🎉 Produk Baru!",
              message: "$productName dari $brandName baru saja hadir!",
              imageUrl: "",
              brand: brandName,
              type: "product",
              productId: savedProductId,
              categories: categoriesList,
            );
            print('✅ Notifikasi produk baru berhasil dikirim ke semua user');
          } catch (notifError) {
            print('⚠️ Produk berhasil disimpan, tapi notifikasi gagal: $notifError');
          }
        }
      } else {
        success = await _service.saveOrUpdateProduct(
          productId: widget.product?.id,
          product: product,
        );
        
        if (success) {
          print('✅ Produk berhasil diperbarui');
          
          final finalImageUrl = _base64Image ?? widget.product?.imageBase64 ?? "";
          print('🖼️ [DEBUG] _base64Image length: ${_base64Image?.length ?? 0}');
          print('🖼️ [DEBUG] widget.product?.imageBase64 length: ${widget.product?.imageBase64?.length ?? 0}');
          print('🖼️ [DEBUG] finalImageUrl length: ${finalImageUrl.length}');
          
          try {
            await _notificationService.sendGlobalNotification(
              title: "Update Produk",
              message: "$productName telah diperbarui!",
              imageUrl: finalImageUrl,
              brand: brandName,
              type: "product",
              productId: widget.product?.id ?? "",
            );
            print('✅ Notifikasi update produk berhasil dibuat');
          } catch (notifError) {
            print('⚠️ Produk berhasil diperbarui, tapi notifikasi gagal: $notifError');
          }
        }
      }
    } catch (e, stack) {
      print('❌ Error saat saveOrUpdateProduct: $e');
      print(stack);
      success = false;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? (isNewProduct
                ? '✅ Produk berhasil ditambahkan & notifikasi terkirim!'
                : '✅ Perubahan berhasil disimpan!')
            : '❌ Gagal menyimpan produk!'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success && mounted) {
      Navigator.pop(context, true);
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
      body: SingleChildScrollView(
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
                                        style:
                                            TextStyle(color: Colors.grey[600])),
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
                              child:
                                  Image.file(_bannerFile!, fit: BoxFit.cover),
                            )
                          : (_bannerBase64 != null && _bannerBase64!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Image.memory(
                                    base64Decode(_bannerBase64!),
                                    fit: BoxFit.cover,
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
                    final linkController =
                        item['link'] as TextEditingController;
                    final priceController =
                        item['price'] as TextEditingController;
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
                                  fit: BoxFit.contain),
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