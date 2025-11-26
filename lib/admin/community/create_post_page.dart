import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/services/supabase_storage_service.dart';

class CreatePostPage extends StatefulWidget {
  final String brand;
  final String? postId;
  final Map<String, dynamic>? initialData;

  const CreatePostPage({
    super.key,
    required this.brand,
    this.postId,
    this.initialData,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storageService = SupabaseStorageService();

  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _imageChanged = false;

  final List<Map<String, dynamic>> _purchaseOptions = [];
  final List<TextEditingController> _urlControllers = [];
  final List<TextEditingController> _priceControllers = [];

  String? _mainCategory;
  String? _subCategory;

  final Map<String, Map<String, String>> _storeLogos = {
    'tokopedia': {'name': 'Tokopedia', 'logo': 'assets/logo_tokopedia.png'},
    'shopee': {'name': 'Shopee', 'logo': 'assets/logo_shopee.png'},
    'blibli': {'name': 'Blibli', 'logo': 'assets/logo_blibli.jpg'},
    'underarmour': {'name': 'Under Armour Official', 'logo': 'assets/logo_under_armour.png'},
    'jordan': {'name': 'Jordan Official', 'logo': 'assets/logo_jordan.png'},
    'puma': {'name': 'Puma Official', 'logo': 'assets/logo_puma.png'},
    'mizuno': {'name': 'Mizuno Official', 'logo': 'assets/logo_mizuno.png'},
    'nike': {'name': 'Nike Official', 'logo': 'assets/logo_nike.png'},
    'adidas': {'name': 'Adidas Official', 'logo': 'assets/logo_adidas.png'},
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    _titleController.text = data['title']?.toString() ?? '';
    _contentController.text = data['content']?.toString() ?? '';
    _descriptionController.text = data['description']?.toString() ?? '';
    
    _existingImageUrl = data['imageUrl1']?.toString();
    _mainCategory = data['mainCategory']?.toString();
    _subCategory = data['subCategory']?.toString();

    final links = data['links'] as List<dynamic>? ?? [];
    for (var link in links) {
      final linkMap = Map<String, dynamic>.from(link as Map);
      _purchaseOptions.add(linkMap);
      
      _urlControllers.add(TextEditingController(text: linkMap['url']?.toString() ?? ''));
      _priceControllers.add(TextEditingController(text: linkMap['price']?.toString() ?? ''));
    }
    
    debugPrint('✅ Loaded existing post data');
    debugPrint('   Image URL: ${_existingImageUrl ?? "No image"}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _descriptionController.dispose();
    
    for (var controller in _urlControllers) {
      controller.dispose();
    }
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Map<String, String> _detectStoreFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    for (var entry in _storeLogos.entries) {
      final cleanKey = entry.key.replaceAll(' ', '').replaceAll('-', '');
      final cleanUrl = lowerUrl.replaceAll(' ', '').replaceAll('-', '').replaceAll('.', '');
      
      if (cleanUrl.contains(cleanKey)) {
        return {
          'store': entry.value['name']!,
          'logoUrl': entry.value['logo']!,
        };
      }
    }
    
    return {'store': 'Other', 'logoUrl': ''};
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageChanged = true;
        });
        
        debugPrint('📸 Image selected: ${pickedFile.path}');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addPurchaseOption() {
    setState(() {
      _purchaseOptions.add({
        'url': '',
        'price': 0,
        'store': '',
        'logoUrl': '',
      });
      _urlControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController());
    });
  }

  void _removePurchaseOption(int index) {
    setState(() {
      _purchaseOptions.removeAt(index);
      _urlControllers[index].dispose();
      _priceControllers[index].dispose();
      _urlControllers.removeAt(index);
      _priceControllers.removeAt(index);
    });
  }

  void _updatePurchaseOptionUrl(int index, String value) {
    _purchaseOptions[index]['url'] = value;
    
    if (value.isNotEmpty) {
      final storeInfo = _detectStoreFromUrl(value);
      setState(() {
        _purchaseOptions[index]['store'] = storeInfo['store']!;
        _purchaseOptions[index]['logoUrl'] = storeInfo['logoUrl']!;
      });
    }
  }

  void _updatePurchaseOptionPrice(int index, String value) {
    _purchaseOptions[index]['price'] = int.tryParse(value) ?? 0;
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ User tidak terautentikasi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _existingImageUrl;

      if (_imageFile != null && _imageChanged) {
        debugPrint('📤 Uploading new image to Supabase...');
        
        finalImageUrl = await _storageService.uploadPostImage(
          file: _imageFile!,
          userId: currentUser.uid,
        );
        
        if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
          await _storageService.deletePostImage(_existingImageUrl!);
          debugPrint('🗑️ Old image deleted');
        }
        
        debugPrint('✅ Image uploaded: $finalImageUrl');
      }

      final communityQuery = await FirebaseFirestore.instance
          .collection('communities')
          .where('brand', isEqualTo: widget.brand)
          .limit(1)
          .get();

      String? communityId;
      
      if (communityQuery.docs.isNotEmpty) {
        communityId = communityQuery.docs.first.id;
      } else {
        final newCommunity = await FirebaseFirestore.instance
            .collection('communities')
            .add({
          'brand': widget.brand,
          'name': 'Kumpulan Brand ${widget.brand} Official',
          'description': 'Komunitas resmi untuk produk ${widget.brand}',
          'createdAt': FieldValue.serverTimestamp(),
        });
        communityId = newCommunity.id;
      }

      final postData = {
        'brand': widget.brand,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl1': finalImageUrl,
        'links': _purchaseOptions,
        'mainCategory': _mainCategory,
        'subCategory': _subCategory,
        'communityId': communityId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.postId == null) {
        postData['createdAt'] = FieldValue.serverTimestamp();
        final postRef = await FirebaseFirestore.instance
            .collection('posts')
            .add(postData);
        debugPrint('✅ Post created: ${postRef.id}');
      } else {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update(postData);
        debugPrint('✅ Post updated: ${widget.postId}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.postId == null
                  ? '✅ Produk berhasil ditambahkan'
                  : '✅ Produk berhasil diupdate',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error saving post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.postId == null ? "Upload Produk" : "Edit Posting",
          style: TextStyle(fontSize: 18.sp, color: AppColors.secondary),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: _buildImagePreview(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul',
                        hintText: 'Masukkan judul posting',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        hintText: 'Masukkan deskripsi singkat',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        alignLabelWithHint: true,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Harga Produk Utama',
                        hintText: 'Contoh: 1500000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16.h),

                    DropdownButtonFormField<String>(
                      value: _mainCategory,
                      decoration: InputDecoration(
                        labelText: 'Kategori Utama',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Basketball', child: Text('Basketball')),
                        DropdownMenuItem(value: 'Soccer', child: Text('Soccer')),
                        DropdownMenuItem(value: 'Volleyball', child: Text('Volleyball')),
                      ],
                      onChanged: (value) => setState(() => _mainCategory = value),
                    ),
                    SizedBox(height: 16.h),

                    DropdownButtonFormField<String>(
                      value: _subCategory,
                      decoration: InputDecoration(
                        labelText: 'Sub Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Trending', child: Text('Trending')),
                        DropdownMenuItem(value: 'Terbaru', child: Text('Terbaru')),
                      ],
                      onChanged: (value) => setState(() => _subCategory = value),
                    ),
                    SizedBox(height: 20.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Opsi Pembelian:',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addPurchaseOption,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    if (_purchaseOptions.isEmpty)
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: const Center(
                          child: Text('Belum ada opsi pembelian'),
                        ),
                      )
                    else
                      ..._buildPurchaseOptions(),

                    SizedBox(height: 24.h),

                    ElevatedButton(
                      onPressed: _savePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        widget.postId == null ? 'Upload Produk' : 'Update Posting',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    }
    
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Image.network(
        _existingImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    }
    
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 60.sp, color: Colors.grey[600]),
        SizedBox(height: 8.h),
        Text('Pilih Foto Produk', style: TextStyle(fontSize: 14.sp)),
      ],
    );
  }

  List<Widget> _buildPurchaseOptions() {
    return List.generate(_purchaseOptions.length, (index) {
      final option = _purchaseOptions[index];
      final hasLogo = option['logoUrl']?.toString().isNotEmpty ?? false;
      
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            if (hasLogo && option['store'] != 'Other')
              Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: Image.asset(
                        option['logoUrl']!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.store),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        option['store'] ?? 'Unknown Store',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _urlControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Link ${index + 1}',
                      hintText: 'https://...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                    ),
                    onChanged: (value) => _updatePurchaseOptionUrl(index, value),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _priceControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Harga',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _updatePurchaseOptionPrice(index, value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePurchaseOption(index),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}