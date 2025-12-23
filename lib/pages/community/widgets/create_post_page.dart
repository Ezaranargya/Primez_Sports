import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/services/supabase_storage_service.dart';

class BrandLinkValidator {
  static final Map<String, List<String>> brandDomains = {
    'Nike': ['nike.com', 'nike.co.id', 'tokopedia.com/nike', 'shopee.co.id/nike', 'blibli.com/nike', 'prosoccer.com', 'mzsports.com.ph'],
    'Adidas': ['adidas.com', 'adidas.co.id', 'tokopedia.com/adidas', 'shopee.co.id/adidas', 'blibli.com/adidas', 'prosoccer.com', 'mzsports.com.ph'],
    'Puma': ['puma.com', 'tokopedia.com/puma', 'shopee.co.id/puma', 'blibli.com/puma', 'prosoccer.com', 'mzsports.com.ph'],
    'Under Armour': ['underarmour.com', 'under-armour.com', 'tokopedia.com/underarmour', 'tokopedia.com/under-armour', 'shopee.co.id/underarmour', 'blibli.com/underarmour', 'prosoccer.com', 'mzsports.com.ph'],
    'Jordan': ['jordan.com', 'nike.com/jordan', 'tokopedia.com/jordan', 'shopee.co.id/jordan', 'blibli.com/jordan', 'prosoccer.com', 'mzsports.com.ph'],
    'Mizuno': ['mizuno.com', 'mizuno.co.id', 'tokopedia.com/mizuno', 'shopee.co.id/mizuno', 'blibli.com/mizuno', 'prosoccer.com', 'mzsports.com.ph'],
  };

  static bool isValidBrandUrl(String url, String brand) {
    if (url.isEmpty) return true;
    try {
      final uri = Uri.parse(url.toLowerCase());
      final host = uri.host.toLowerCase();
      final fullUrl = uri.toString().toLowerCase();
      
      final allowedDomains = brandDomains[brand] ?? [];
      
      for (final domain in allowedDomains) {
        final cleanDomain = domain.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
        final cleanHost = host.replaceAll(' ', '').replaceAll('-', '');
        final cleanUrl = fullUrl.replaceAll(' ', '').replaceAll('-', '');
        
        if (cleanHost.contains(cleanDomain.split('/')[0]) || 
            cleanDomain.split('/')[0].contains(cleanHost)) {
          return true;
        }
        
        if (cleanUrl.contains(cleanDomain)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  static String getErrorMessage(String brand) {
    final domains = brandDomains[brand] ?? [];
    if (domains.isEmpty) return 'Link tidak valid';
    return 'Link harus dari: ${domains.take(3).join(", ")}';
  }
}

class UserCreatePostPage extends StatefulWidget {
  final String brand;
  final String? postId;
  final Map<String, dynamic>? initialData;

  const UserCreatePostPage({
    super.key,
    required this.brand,
    this.postId,
    this.initialData,
  });

  @override
  State<UserCreatePostPage> createState() => _UserCreatePostPageState();
}

class _UserCreatePostPageState extends State<UserCreatePostPage> {
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
    
    for (var i = 0; i < links.length; i++) {
      final link = links[i];
      final linkMap = Map<String, dynamic>.from(link as Map);
      
      _purchaseOptions.add(linkMap);
      
      final url = linkMap['url']?.toString() ?? '';
      _urlControllers.add(TextEditingController(text: url));
      
      final priceValue = linkMap['price'];
      String priceText = '';
      
      if (priceValue != null) {
        if (priceValue is int) {
          priceText = priceValue.toString();
        } else if (priceValue is double) {
          priceText = priceValue.toInt().toString();
        } else if (priceValue is String) {
          priceText = priceValue.replaceAll(RegExp(r'[^0-9]'), '');
        }
      }
      
      _priceControllers.add(TextEditingController(text: priceText));
    }
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
    
    // ✅ PERBAIKAN: Untuk prosoccer & mzsports, tampilkan brand name & logo
    if (lowerUrl.contains('prosoccer.com') || lowerUrl.contains('mzsports.com')) {
      // Deteksi brand dari path/product name di URL
      if (lowerUrl.contains('adidas') || lowerUrl.contains('/products/adidas')) {
        return {
          'store': 'Adidas Official',
          'logoUrl': 'assets/logo_adidas.png',
        };
      } else if (lowerUrl.contains('nike') || lowerUrl.contains('/products/nike')) {
        return {
          'store': 'Nike Official',
          'logoUrl': 'assets/logo_nike.png',
        };
      } else if (lowerUrl.contains('puma') || lowerUrl.contains('/products/puma')) {
        return {
          'store': 'Puma Official',
          'logoUrl': 'assets/logo_puma.png',
        };
      } else if (lowerUrl.contains('mizuno') || lowerUrl.contains('/products/mizuno')) {
        return {
          'store': 'Mizuno Official',
          'logoUrl': 'assets/logo_mizuno.png',
        };
      } else if (lowerUrl.contains('jordan') || lowerUrl.contains('/products/jordan')) {
        return {
          'store': 'Jordan Official',
          'logoUrl': 'assets/logo_jordan.png',
        };
      } else if (lowerUrl.contains('under') && lowerUrl.contains('armour')) {
        return {
          'store': 'Under Armour Official',
          'logoUrl': 'assets/logo_under_armour.png',
        };
      } else {
        // Fallback: jika tidak ada brand terdeteksi dari URL
        return {
          'store': 'Official Store',
          'logoUrl': '',
        };
      }
    }
    
    // Deteksi Under Armour (dengan spasi)
    if (lowerUrl.contains('underarmour.com') || lowerUrl.contains('under-armour.com')) {
      return {
        'store': 'Under Armour Official',
        'logoUrl': 'assets/logo_under_armour.png',
      };
    }
    
    if (lowerUrl.contains('nike.com')) {
      return {
        'store': 'Nike Official',
        'logoUrl': 'assets/logo_nike.png',
      };
    }
    
    if (lowerUrl.contains('adidas.com')) {
      return {
        'store': 'Adidas Official',
        'logoUrl': 'assets/logo_adidas.png',
      };
    }
    
    if (lowerUrl.contains('jordan.com')) {
      return {
        'store': 'Jordan Official',
        'logoUrl': 'assets/logo_jordan.png',
      };
    }
    
    if (lowerUrl.contains('puma.com')) {
      return {
        'store': 'Puma Official',
        'logoUrl': 'assets/logo_puma.png',
      };
    }
    
    if (lowerUrl.contains('mizuno.com')) {
      return {
        'store': 'Mizuno Official',
        'logoUrl': 'assets/logo_mizuno.png',
      };
    }
    
    if (lowerUrl.contains('tokopedia.com')) {
      return {
        'store': 'Tokopedia',
        'logoUrl': 'assets/logo_tokopedia.png',
      };
    }
    
    if (lowerUrl.contains('shopee.co.id') || lowerUrl.contains('shopee.com')) {
      return {
        'store': 'Shopee',
        'logoUrl': 'assets/logo_shopee.png',
      };
    }
    
    if (lowerUrl.contains('blibli.com')) {
      return {
        'store': 'Blibli',
        'logoUrl': 'assets/logo_blibli.jpg',
      };
    }
    
    return {'store': 'Other', 'logoUrl': ''};
  }

  Future<void> _pickImage() async {
    try {
      debugPrint('🎯 Starting image picker...');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        debugPrint('📥 Image picked: ${pickedFile.path}');
        
        // Copy file ke app directory untuk mencegah PathNotFoundException
        final appDir = Directory.systemTemp;
        final fileName = 'post_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${appDir.path}/$fileName');
        
        debugPrint('📋 Copying to: ${savedImage.path}');
        
        // Copy file dari picker ke lokasi persistent
        final bytes = await File(pickedFile.path).readAsBytes();
        await savedImage.writeAsBytes(bytes);
        
        final fileExists = await savedImage.exists();
        final fileSize = await savedImage.length();
        
        debugPrint('✅ File copied - exists: $fileExists, size: $fileSize bytes');
        
        setState(() {
          _imageFile = savedImage;
          _imageChanged = true;
        });
        
        debugPrint('✅ State updated - _imageFile: ${_imageFile?.path}, _imageChanged: $_imageChanged');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Gambar berhasil dipilih'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        debugPrint('❌ No image selected');
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
      _purchaseOptions[index]['store'] = storeInfo['store']!;
      _purchaseOptions[index]['logoUrl'] = storeInfo['logoUrl']!;
      
      if (storeInfo['logoUrl']!.isNotEmpty) {
        setState(() {});
      }
    }
  }

  void _updatePurchaseOptionPrice(int index, String value) {
    final parsedValue = int.tryParse(value.trim());
    _purchaseOptions[index]['price'] = parsedValue ?? 0;
  }

  bool _validatePurchaseLinks() {
    for (int i = 0; i < _urlControllers.length; i++) {
      final url = _urlControllers[i].text.trim();
      
      if (url.isNotEmpty && !BrandLinkValidator.isValidBrandUrl(url, widget.brand)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Link ${i + 1}: ${BrandLinkValidator.getErrorMessage(widget.brand)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // VALIDASI GAMBAR WAJIB
    final hasNewImage = _imageFile != null;
    final hasExistingImage = _existingImageUrl != null && _existingImageUrl!.isNotEmpty;
    
    if (!hasNewImage && !hasExistingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Silakan pilih gambar produk terlebih dahulu'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!_validatePurchaseLinks()) {
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

      // Upload gambar baru jika ada
      if (hasNewImage) {
        debugPrint('📤 Uploading new image to Supabase...');
        
        // Validasi file exists sebelum upload
        if (!await _imageFile!.exists()) {
          debugPrint('❌ Image file does not exist: ${_imageFile!.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ File gambar tidak ditemukan, silakan pilih ulang'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        
        try {
          final fileSize = await _imageFile!.length();
          debugPrint('📂 File exists, size: $fileSize bytes');
          
          finalImageUrl = await _storageService.uploadPostImage(
            file: _imageFile!,
            userId: currentUser.uid,
          );
          
          if (finalImageUrl == null || finalImageUrl.isEmpty) {
            throw Exception('Upload returned null or empty URL');
          }
          
          debugPrint('✅ Image uploaded successfully: $finalImageUrl');
          
          // Hapus gambar lama jika ada
          if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
            try {
              await _storageService.deletePostImage(_existingImageUrl!);
              debugPrint('🗑️ Old image deleted');
            } catch (e) {
              debugPrint('⚠️ Failed to delete old image: $e');
            }
          }
        } catch (e) {
          debugPrint('❌ Image upload failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Gagal upload gambar: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Final check - pastikan ada URL gambar
      if (finalImageUrl == null || finalImageUrl.isEmpty) {
        debugPrint('❌ No image URL available after upload attempt');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Gambar belum tersedia, silakan pilih gambar'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      String username = 'User';
      String? userPhotoUrl;
      
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          username = userData?['username'] ?? 
                     userData?['name'] ?? 
                     userData?['displayName'] ?? 
                     currentUser.displayName ?? 
                     currentUser.email?.split('@')[0] ?? 
                     'User';
          userPhotoUrl = userData?['photoURL'] ?? 
                        userData?['userPhotoUrl'] ?? 
                        currentUser.photoURL;
        } else {
          username = currentUser.displayName ?? 
                    currentUser.email?.split('@')[0] ?? 
                    'User';
          userPhotoUrl = currentUser.photoURL;
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching user data: $e');
        username = currentUser.displayName ?? 
                  currentUser.email?.split('@')[0] ?? 
                  'User';
        userPhotoUrl = currentUser.photoURL;
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

      final finalLinks = List<Map<String, dynamic>>.from(_purchaseOptions);
      for (int i = 0; i < finalLinks.length; i++) {
        finalLinks[i]['url'] = _urlControllers[i].text.trim();
        finalLinks[i]['price'] = int.tryParse(_priceControllers[i].text.trim()) ?? 0;
      }

      final postData = {
        'brand': widget.brand,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl1': finalImageUrl,
        'links': finalLinks,
        'mainCategory': _mainCategory,
        'subCategory': _subCategory,
        'communityId': communityId,
        'userId': currentUser.uid,
        'username': username,
        'userPhotoUrl': userPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.postId == null) {
        postData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('posts').add(postData);
      } else {
        final existingDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

        postData['createdAt'] = existingDoc['createdAt'];

        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update(postData);
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
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Error saving post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
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
                          border: Border.all(
                            color: (_imageFile == null && _existingImageUrl == null) 
                                ? Colors.red 
                                : Colors.grey[400]!,
                            width: (_imageFile == null && _existingImageUrl == null) ? 2 : 1,
                          ),
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
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Harga tidak boleh kosong';
                        }
                        final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (cleanValue.isEmpty || int.tryParse(cleanValue) == null) {
                          return 'Harga harus berupa angka';
                        }
                        return null;
                      },
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
                          icon: const Icon(Icons.add, color: AppColors.primary),
                          label: Text('Tambah', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    Container(
                      padding: EdgeInsets.all(12.w),
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Link harus dari official store atau marketplace resmi ${widget.brand}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

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
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _imageFile!, 
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder();
            },
          ),
          Positioned(
            bottom: 8.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, color: Colors.white, size: 14),
                  SizedBox(width: 4.w),
                  const Text(
                    'Tap untuk ubah',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _existingImageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 60.sp, color: Colors.red[300]),
                    SizedBox(height: 8.h),
                    Text(
                      'Gagal memuat gambar',
                      style: TextStyle(fontSize: 12.sp, color: Colors.red),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Tap untuk pilih gambar baru',
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 8.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, color: Colors.white, size: 14),
                  SizedBox(width: 4.w),
                  const Text(
                    'Tap untuk ubah',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        Text(
          'Pilih Foto Produk',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            'WAJIB',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
                  child: TextFormField(
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
                  child: TextFormField(
                    controller: _priceControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Harga',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      _updatePurchaseOptionPrice(index, value);
                    },
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