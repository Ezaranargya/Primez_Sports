import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/services/supabase_storage_service.dart';

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
  final _storageService = SupabaseStorageService();
  
  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedCategories = [];
  final List<ContentBlock> _contentItems = [];
  
  File? _mainImageFile;
  String? _existingMainImageUrl;
  bool _isLoading = false;
  bool _mainImageChanged = false;
  
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
    _existingMainImageUrl = news.imageUrl1;
    
    for (var item in news.content) {
      _contentItems.add(ContentBlock(
        type: item.type,
        value: item.value,
        caption: item.caption,
      ));
    }
    
    debugPrint('✅ Loaded existing news');
    debugPrint('   Main image URL: ${_existingMainImageUrl ?? "No image"}');
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
      final file = File(pickedFile.path);
      
      setState(() {
        if (isMainImage) {
          _mainImageFile = file;
          _mainImageChanged = true;
          debugPrint('📸 Main image selected');
        } else if (contentIndex != null) {
          _contentItems[contentIndex] = ContentBlock(
            type: 'image',
            value: file.path, 
            caption: _contentItems[contentIndex].caption,
            imageFile: file,
          );
          debugPrint('📸 Content image selected at index $contentIndex');
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
    
    if (_mainImageFile == null && _existingMainImageUrl == null) {
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
      String? mainImageUrl = _existingMainImageUrl;

      if (_mainImageFile != null && _mainImageChanged) {
        debugPrint('📤 Uploading main image to Supabase...');
        
        mainImageUrl = await _storageService.uploadNewsImage(_mainImageFile!);
        
        if (_existingMainImageUrl != null && _existingMainImageUrl!.isNotEmpty) {
          await _storageService.deleteImage(_existingMainImageUrl!);
          debugPrint('🗑️ Old main image deleted');
        }
        
        debugPrint('✅ Main image uploaded: $mainImageUrl');
      }

      final processedContent = <ContentBlock>[];
      
      for (var item in _contentItems) {
        if (item.type == 'image' && item.imageFile != null) {
          debugPrint('📤 Uploading content image...');
          
          final imageUrl = await _storageService.uploadNewsImage(item.imageFile!);
          
          processedContent.add(ContentBlock(
            type: 'image',
            value: imageUrl ?? '',
            caption: item.caption,
          ));
          
          debugPrint('✅ Content image uploaded: $imageUrl');
        } else {
          processedContent.add(item);
        }
      }

      final news = News(
        id: widget.news?.id ?? '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        author: _authorController.text.trim(),
        brand: _brandController.text.trim(),
        date: _selectedDate,
        createdAt: widget.news?.createdAt ?? DateTime.now(),
        categories: _selectedCategories,
        imageUrl1: mainImageUrl!,
        content: processedContent,
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
                  ? '✅ Berita berhasil ditambahkan' 
                  : '✅ Berita berhasil diperbarui'
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error saving news: $e');
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
            if (_mainImageFile != null || _existingMainImageUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: _mainImageFile != null
                        ? Image.file(_mainImageFile!, height: 200.h, width: double.infinity, fit: BoxFit.cover)
                        : Image.network(_existingMainImageUrl!, height: 200.h, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: IconButton(
                      onPressed: () => setState(() {
                        _mainImageFile = null;
                        _existingMainImageUrl = null;
                        _mainImageChanged = true;
                      }),
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
                        Text('Pilih Gambar', style: TextStyle(fontSize: 14.sp, fontFamily: 'Poppins')),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: const TextStyle(fontFamily: 'Poppins'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Card(
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppColors.primary),
        title: const Text('Tanggal Publikasi', style: TextStyle(fontFamily: 'Poppins')),
        subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
        onTap: _selectDate,
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
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
            Text('Konten Berita', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            ElevatedButton.icon(
              onPressed: _addContentItem,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_contentItems.isEmpty)
          Card(
            color: AppColors.secondary,
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Center(child: Text('Belum ada konten', style: TextStyle(fontSize: 14.sp, fontFamily: 'Poppins'))),
            ),
          )
        else
          ...List.generate(_contentItems.length, (index) => _buildContentItemCard(index)),
      ],
    );
  }

  Widget _buildContentItemCard(int index) {
    final item = _contentItems[index];
    final isImageType = item.type == 'image';
    
    return Card(
      color: AppColors.secondary,
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Konten ${index + 1} - ${isImageType ? "Image" : "Text"}', 
                     style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => _removeContentItem(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            if (!isImageType)
              TextFormField(
                initialValue: item.value,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Teks', border: OutlineInputBorder()),
                onChanged: (value) {
                  _contentItems[index] = ContentBlock(type: 'text', value: value);
                },
              )
            else ...[
              if (item.imageFile != null || item.value.startsWith('http'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: item.imageFile != null 
                      ? Image.file(item.imageFile!, height: 150.h, width: double.infinity, fit: BoxFit.cover)
                      : Image.network(item.value, height: 150.h, width: double.infinity, fit: BoxFit.cover),
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
                    child: Center(child: Icon(Icons.add_photo_alternate, size: 40.sp)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveNews,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}