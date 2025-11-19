import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';


class AdminNewsFormPage extends StatefulWidget {
  final News? news;

  const AdminNewsFormPage({super.key, this.news});

  @override
  State<AdminNewsFormPage> createState() => _AdminNewsFormPageState();
}

class _AdminNewsFormPageState extends State<AdminNewsFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _authorController = TextEditingController();
  final _brandController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedCategories = [];
  final List<ContentBlock> _contentItems = [];
  
  String? _mainImageBase64;
  bool _isLoading = false;
  
  final List<String> _availableCategories = [
    'Trending',
    'Terbaru',
    'Soccer',
    'Basketball',
    'Volleyball',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.news != null) {
      _loadNewsData();
    }
  }

  void _loadNewsData() {
    final news = widget.news!;
    _titleController.text = news.title;
    _subtitleController.text = news.subtitle;
    _authorController.text = news.author;
    _brandController.text = news.brand;
    _selectedDate = news.date;
    _selectedCategories.addAll(news.categories);
    _mainImageBase64 = news.imageUrl1;
    
    
    for (var item in news.content) {
      _contentItems.add(ContentBlock(
        type: item.type,
        value: item.value,
        caption: item.caption,
      ));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _authorController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool isMainImage = false, int? contentIndex}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      setState(() {
        if (isMainImage) {
          _mainImageBase64 = base64String;
        } else if (contentIndex != null) {
          _contentItems[contentIndex] = ContentBlock(
            type: 'image',
            value: base64String,
            caption: _contentItems[contentIndex].caption,
          );
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addContentItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Tipe Konten', style: TextStyle(fontFamily: 'Poppins')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Text', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                setState(() {
                  _contentItems.add(ContentBlock(type: 'text', value: ''));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                setState(() {
                  _contentItems.add(ContentBlock(type: 'image', value: ''));
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeContentItem(int index) {
    setState(() {
      _contentItems.removeAt(index);
    });
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mainImageBase64 == null || _mainImageBase64!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih gambar utama'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih minimal satu kategori'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final news = News(
        id: widget.news?.id ?? '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        author: _authorController.text.trim(),
        brand: _brandController.text.trim(),
        date: _selectedDate,
        createdAt: widget.news?.createdAt ?? DateTime.now(),
        categories: _selectedCategories,
        imageUrl1: _mainImageBase64!,
        content: _contentItems,
        readBy: widget.news?.readBy ?? [],
        isNew: widget.news == null ? true : widget.news!.isNew,
      );

      if (widget.news == null) {
        await FirebaseFirestore.instance.collection('news').add(news.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection('news')
            .doc(widget.news!.id)
            .update(news.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.news == null 
                  ? 'Berita berhasil ditambahkan' 
                  : 'Berita berhasil diperbarui'
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
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.news == null ? 'Tambah Berita' : 'Edit Berita',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _buildMainImageSection(),
            SizedBox(height: 20.h),
            _buildTextField(
              controller: _titleController,
              label: 'Judul Berita',
              hint: 'Masukkan judul berita',
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Judul tidak boleh kosong';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _subtitleController,
              label: 'Subtitle',
              hint: 'Masukkan subtitle (opsional)',
              maxLines: 3,
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _authorController,
              label: 'Penulis',
              hint: 'Masukkan nama penulis',
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _brandController,
              label: 'Brand',
              hint: 'Masukkan brand (opsional)',
            ),
            SizedBox(height: 16.h),
            _buildDatePicker(),
            SizedBox(height: 16.h),
            _buildCategorySection(),
            SizedBox(height: 20.h),
            _buildContentSection(),
            SizedBox(height: 20.h),
            _buildSaveButton(),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImageSection() {
    return Card(
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gambar Utama',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 12.h),
            if (_mainImageBase64 != null && _mainImageBase64!.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: _buildImagePreview(_mainImageBase64!),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: IconButton(
                      onPressed: () => setState(() => _mainImageBase64 = null),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: () => _pickImage(isMainImage: true),
                child: Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 50.sp, color: Colors.grey),
                        SizedBox(height: 8.h),
                        Text(
                          'Pilih Gambar',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Card(
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: const TextStyle(fontFamily: 'Poppins'),
            hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Card(
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppColors.primary),
        title: const Text(
          'Tanggal Publikasi',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.secondary),
        onTap: _selectDate,
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(
                    category,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Konten Berita',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addContentItem,
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: const Text(
                'Tambah',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_contentItems.isEmpty)
          Card(
            color: AppColors.secondary,
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.article_outlined, size: 50.sp, color: Colors.grey[400]),
                    SizedBox(height: 8.h),
                    Text(
                      'Belum ada konten',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...List.generate(_contentItems.length, (index) {
            return _buildContentItemCard(index);
          }),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveNews,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ), 
          child: _isLoading
          ? const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          )
          : const Text(
            'Simpan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: AppColors.backgroundColor,
              fontSize: 16,
            ),
          )
        ),
      ),
    );
  }

  Widget _buildContentItemCard(int index) {
    final item = _contentItems[index];
    final isImageType = item.type == 'image';
    
    return Card(
      color: AppColors.secondary,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isImageType ? Icons.image : Icons.text_fields,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Konten ${index + 1} - ${isImageType ? "Image" : "Text"}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _removeContentItem(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            
            if (!isImageType) ...[
              TextFormField(
                initialValue: item.value,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Teks',
                  hintText: 'Masukkan teks konten',
                  labelStyle: const TextStyle(fontFamily: 'Poppins'),
                  hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onChanged: (value) {
                  _contentItems[index] = ContentBlock(
                    type: 'text',
                    value: value,
                    caption: item.caption,
                  );
                },
              ),
            ]
            else ...[
              if (item.value.isNotEmpty)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: _buildImagePreview(item.value),
                    ),
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _contentItems[index] = ContentBlock(
                              type: 'image',
                              value: '',
                              caption: item.caption,
                            );
                          });
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: () => _pickImage(contentIndex: index),
                  child: Container(
                    height: 150.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40.sp, color: Colors.grey),
                          SizedBox(height: 8.h),
                          Text(
                            'Pilih Gambar',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (item.value.isNotEmpty) ...[
                SizedBox(height: 12.h),
                TextFormField(
                  initialValue: item.caption,
                  decoration: InputDecoration(
                    labelText: 'Caption Gambar',
                    hintText: 'Masukkan caption (opsional)',
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onChanged: (value) {
                    _contentItems[index] = ContentBlock(
                      type: 'image',
                      value: item.value,
                      caption: value,
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imageData) {
    return ProductImage(
      image: imageData,
      width: double.infinity,
      height: 200.h,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12.r),
    );
  }
}