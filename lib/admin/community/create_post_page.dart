import 'dart:io';
import 'dart:typed_data'; 
import 'dart:convert'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/theme/app_colors.dart';

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

  String? _imageUrl;
  String? _imagePathForDisplay; 
  Uint8List? _imageBytesForUpload;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  String? _imageBase64;

  final List<Map<String, dynamic>> _purchaseOptions = [];
  final List<TextEditingController> _urlControllers = [];
  final List<TextEditingController> _priceControllers = [];

  String? _mainCategory;
  String? _subCategory;

  final Map<String, Map<String, String>> _storeLogos = {
    'tokopedia': {
      'name': 'Tokopedia',
      'logo': 'assets/logo_tokopedia.png',
    },
    'shopee': {
      'name': 'Shopee',
      'logo': 'assets/logo_shopee.png',
    },
    'blibli': {
      'name': 'Blibli',
      'logo': 'assets/logo_blibli.jpg',
    },
    'underarmour': {
      'name': 'Under Armour Official',
      'logo': 'assets/logo_under_armour.png',
    },
    'under-armour': {
      'name': 'Under Armour Official',
      'logo': 'assets/logo_under_armour.png',
    },
    'under armour': {
      'name': 'Under Armour Official',
      'logo': 'assets/logo_under_armour.png',
    },
    'jordan': {
      'name': 'Jordan Official',
      'logo': 'assets/logo_jordan.png',
    },
    'puma': {
      'name': 'Puma Official',
      'logo': 'assets/logo_puma.png',
    },
    'mizuno': {
      'name': 'Mizuno Official',
      'logo': 'assets/logo_mizuno.png',
    },
    'nike': {
      'name': 'Nike Official',
      'logo': 'assets/logo_nike.png',
    },
    'adidas': {
      'name': 'Adidas Official',
      'logo': 'assets/logo_adidas.png',
    },
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
    
    final imageUrl = data['imageUrl']?.toString() ?? '';
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      _imageUrl = imageUrl;
    }
    
    final imageBase64 = data['imageBase64']?.toString() ?? '';
    if (imageBase64.isNotEmpty) {
      _imageBase64 = imageBase64;
      print('✅ Loaded existing imageBase64 (${imageBase64.length} chars)');
    }
    
    _mainCategory = data['mainCategory']?.toString();
    _subCategory = data['subCategory']?.toString();

    final links = data['links'] as List<dynamic>? ?? [];
    for (var link in links) {
      final linkMap = Map<String, dynamic>.from(link as Map);
      _purchaseOptions.add(linkMap);
      
      final urlController = TextEditingController(text: linkMap['url']?.toString() ?? '');
      final priceController = TextEditingController(text: linkMap['price']?.toString() ?? '');
      
      _urlControllers.add(urlController);
      _priceControllers.add(priceController);
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
    
    return {
      'store': 'Other',
      'logoUrl': '',
    };
  }

  Widget _buildImageFromBase64(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Error decoding base64 image: $error');
          return _buildImagePlaceholder();
        },
      );
    } catch (e) {
      debugPrint('❌ Error decoding base64 image: $e');
      return _buildImagePlaceholder();
    }
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
        final bytes = await pickedFile.readAsBytes();
        
        final base64String = base64Encode(bytes);
        
        setState(() {
          _imagePathForDisplay = pickedFile.path;
          _imageBytesForUpload = bytes;
          _imageUrl = null;
          _imageBase64 = base64String;
        });
        
        debugPrint('✅ Image converted to base64 (${base64String.length} chars)');
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

    setState(() => _isLoading = true);

    try {
      String finalImageUrl = '';
      
      final communityQuery = await FirebaseFirestore.instance
          .collection('communities')
          .where('brand', isEqualTo: widget.brand)
          .limit(1)
          .get();

      String? communityId;
      
      if (communityQuery.docs.isNotEmpty) {
        communityId = communityQuery.docs.first.id;
        debugPrint('✅ Found existing community: $communityId for ${widget.brand}');
      } else {
        debugPrint('⚠️ Community not found for ${widget.brand}, creating new one...');
        final newCommunity = await FirebaseFirestore.instance
            .collection('communities')
            .add({
          'brand': widget.brand,
          'name': 'Kumpulan Brand ${widget.brand} Official',
          'description': 'Komunitas resmi untuk produk ${widget.brand}',
          'createdAt': FieldValue.serverTimestamp(),
        });
        communityId = newCommunity.id;
        debugPrint('✅ Created new community: $communityId');
      }

      final finalImageBase64 = _imageBase64 ?? widget.initialData?['imageBase64']?.toString() ?? '';
      
      debugPrint('📸 [DEBUG] Saving post with:');
      debugPrint('   - imageUrl: $finalImageUrl (empty is correct)');
      debugPrint('   - imageBase64 length: ${finalImageBase64.length}');

      final postData = {
        'brand': widget.brand,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': finalImageUrl,
        'imageBase64': finalImageBase64, 
        'links': _purchaseOptions,
        'mainCategory': _mainCategory,
        'subCategory': _subCategory,
        'communityId': communityId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.postId == null) {
        postData['createdAt'] = FieldValue.serverTimestamp();
        
        debugPrint('📝 Creating new post for ${widget.brand}...');
        
        final postRef = await FirebaseFirestore.instance
            .collection('posts')
            .add(postData);

        debugPrint('✅ Post created: ${postRef.id}');
      } else {
        debugPrint('📝 Updating post ${widget.postId}...');
        
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
                  ? '✅ Produk berhasil ditambahkan ke komunitas ${widget.brand}'
                  : '✅ Produk berhasil diupdate',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
            duration: const Duration(seconds: 3),
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  if (_isUploadingImage) ...[
                    SizedBox(height: 16.h),
                    Text(
                      'Uploading image: ${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: 200.w,
                      child: LinearProgressIndicator(value: _uploadProgress),
                    ),
                  ],
                ],
              ),
            )
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
                        child: _imagePathForDisplay != null 
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.file(
                                  File(_imagePathForDisplay!), 
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildImagePlaceholder();
                                  },
                                ),
                              )
                            : _imageBase64 != null && _imageBase64!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: _buildImageFromBase64(_imageBase64!),
                                  )
                                : _imageUrl != null && _imageUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12.r),
                                        child: Image.network(
                                          _imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return _buildImagePlaceholder();
                                          },
                                        ),
                                      )
                                    : _buildImagePlaceholder(),
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
                      onChanged: (value) {
                        setState(() {
                          _mainCategory = value;
                        });
                      },
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
                      onChanged: (value) {
                        setState(() {
                          _subCategory = value;
                        });
                      },
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
                            color: Colors.black87,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addPurchaseOption,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
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
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada opsi pembelian',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_purchaseOptions.length, (index) {
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasLogo && option['store'] != 'Other')
                                Container(
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40.w,
                                        height: 40.w,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6.r),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6.r),
                                          child: Image.asset(
                                            option['logoUrl']!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.store,
                                                size: 24.sp,
                                                color: Colors.grey[400],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              option['store'] ?? 'Unknown Store',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              'Terdeteksi otomatis',
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: Colors.green[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20.sp,
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
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 10.h,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.link,
                                          size: 20.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      onChanged: (value) {
                                        _updatePurchaseOptionUrl(index, value);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: TextField(
                                      controller: _priceControllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Harga',
                                        hintText: '1500000',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 10.h,
                                        ),
                                        prefixText: 'Rp ',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _updatePurchaseOptionPrice(index, value);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                        size: 20.sp,
                                      ),
                                      onPressed: () => _removePurchaseOption(index),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(
                                        minWidth: 36.w,
                                        minHeight: 36.h,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    SizedBox(height: 24.h),

                    ElevatedButton(
                      onPressed: _isUploadingImage ? null : _savePost,
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

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 60.sp,
          color: Colors.grey[600],
        ),
        SizedBox(height: 8.h),
        Text(
          'Pilih Foto Produk',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}