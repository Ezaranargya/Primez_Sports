import 'dart:io';
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

  String? _imagePath;
  File? _imageFile;
  bool _isLoading = false;

  // Purchase options list
  final List<Map<String, dynamic>> _purchaseOptions = [];

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
    _imagePath = data['imageUrl']?.toString();

    final links = data['links'] as List<dynamic>? ?? [];
    _purchaseOptions.addAll(
      links.map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imagePath = pickedFile.path;
      });
    }
  }

  void _addPurchaseOption() {
    showDialog(
      context: context,
      builder: (context) {
        final linkController = TextEditingController();
        final priceController = TextEditingController();
        final storeController = TextEditingController();
        final logoController = TextEditingController();

        return AlertDialog(
          title: const Text('Tambah Opsi Pembelian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: 'Link/URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    hintText: '1500000',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: storeController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Toko (opsional)',
                    hintText: 'Tokopedia',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: logoController,
                  decoration: const InputDecoration(
                    labelText: 'Logo URL (opsional)',
                    hintText: 'assets/...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (linkController.text.isNotEmpty) {
                  setState(() {
                    _purchaseOptions.add({
                      'url': linkController.text,
                      'price': int.tryParse(priceController.text) ?? 0,
                      'store': storeController.text,
                      'logoUrl': logoController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _removePurchaseOption(int index) {
    setState(() {
      _purchaseOptions.removeAt(index);
    });
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final postData = {
        'brand': widget.brand,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imagePath ?? '',
        'links': _purchaseOptions,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.postId == null) {
        // Create new post
        postData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('posts').add(postData);
      } else {
        // Update existing post
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
                  ? 'Posting berhasil dibuat'
                  : 'Posting berhasil diupdate',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
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
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imagePath != null && _imagePath!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Image.asset(
                                      _imagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return _buildImagePlaceholder();
                                      },
                                    ),
                                  )
                                : _buildImagePlaceholder(),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Title Field
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

                    // Brand Display (read-only)
                    TextFormField(
                      initialValue: widget.brand,
                      decoration: InputDecoration(
                        labelText: 'Brand',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      enabled: false,
                    ),
                    SizedBox(height: 16.h),

                    // Description Field
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

                    // Content/Main Price Field
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

                    // Main Category Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Kategori Utama',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Running', child: Text('Running')),
                        DropdownMenuItem(value: 'Basketball', child: Text('Basketball')),
                        DropdownMenuItem(value: 'Football', child: Text('Football')),
                        DropdownMenuItem(value: 'Training', child: Text('Training')),
                        DropdownMenuItem(value: 'Casual', child: Text('Casual')),
                      ],
                      onChanged: (value) {},
                    ),
                    SizedBox(height: 16.h),

                    // Sub Category Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Sub Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Men', child: Text('Men')),
                        DropdownMenuItem(value: 'Women', child: Text('Women')),
                        DropdownMenuItem(value: 'Unisex', child: Text('Unisex')),
                        DropdownMenuItem(value: 'Kids', child: Text('Kids')),
                      ],
                      onChanged: (value) {},
                    ),
                    SizedBox(height: 20.h),

                    // Purchase Options Section
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

                    // Purchase Options List
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
                        return Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (option['store'] != null &&
                                        option['store'].toString().isNotEmpty)
                                      Text(
                                        option['store'],
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (option['price'] != null &&
                                        option['price'] > 0)
                                      Text(
                                        'Rp ${_formatPrice(option['price'])}',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    Text(
                                      option['url'] ?? '',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.blue,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20.sp,
                                ),
                                onPressed: () => _removePurchaseOption(index),
                              ),
                            ],
                          ),
                        );
                      }),
                    SizedBox(height: 24.h),

                    // Submit Button
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

  String _formatPrice(dynamic price) {
    if (price == null) return '0';

    try {
      final numPrice = price is int ? price : int.parse(price.toString());
      return numPrice.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
    } catch (e) {
      return price.toString();
    }
  }
}