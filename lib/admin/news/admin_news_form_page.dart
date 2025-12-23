import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/models/news_model.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/services/supabase_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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

  // FIX: Fungsi untuk menyalin file ke lokasi permanen
  Future<File> _copyImageToAppDirectory(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final newPath = path.join(appDir.path, fileName);
      
      final newFile = await imageFile.copy(newPath);
      debugPrint('✅ Image copied to permanent location: $newPath');
      return newFile;
    } catch (e) {
      debugPrint('❌ Error copying image: $e');
      return imageFile; // Return original if copy fails
    }
  }

  Future<void> _pickImage({bool isMainImage = false, int? contentIndex}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // FIX: Copy file to permanent location immediately
        final permanentFile = await _copyImageToAppDirectory(file);
        
        setState(() {
          if (isMainImage) {
            _mainImageFile = permanentFile;
            _mainImageChanged = true;
            debugPrint('📸 Main image selected and stored: ${permanentFile.path}');
          } else if (contentIndex != null) {
            _contentItems[contentIndex] = ContentBlock(
              type: 'image',
              value: permanentFile.path, 
              caption: _contentItems[contentIndex].caption,
              imageFile: permanentFile,
            );
            debugPrint('📸 Content image selected at index $contentIndex: ${permanentFile.path}');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

      // FIX: Upload main image with proper error handling
      if (_mainImageFile != null && _mainImageChanged) {
        debugPrint('📤 Uploading main image to Supabase...');
        debugPrint('   File path: ${_mainImageFile!.path}');
        debugPrint('   File exists: ${await _mainImageFile!.exists()}');
        
        // Verify file exists before upload
        if (!await _mainImageFile!.exists()) {
          throw Exception('Main image file not found at path: ${_mainImageFile!.path}');
        }
        
        mainImageUrl = await _storageService.uploadNewsImage(_mainImageFile!);
        
        // FIX: Check if upload was successful
        if (mainImageUrl == null || mainImageUrl.isEmpty) {
          throw Exception('Failed to upload main image - received null or empty URL');
        }
        
        // Delete old image only after successful upload
        if (_existingMainImageUrl != null && _existingMainImageUrl!.isNotEmpty) {
          try {
            await _storageService.deleteImage(_existingMainImageUrl!);
            debugPrint('🗑️ Old main image deleted');
          } catch (e) {
            debugPrint('⚠️ Warning: Could not delete old image: $e');
            // Don't fail the whole operation if delete fails
          }
        }
        
        debugPrint('✅ Main image uploaded successfully: $mainImageUrl');
      }

      // FIX: Process content items with better error handling
      final processedContent = <ContentBlock>[];
      
      for (int i = 0; i < _contentItems.length; i++) {
        final item = _contentItems[i];
        
        if (item.type == 'image' && item.imageFile != null) {
          debugPrint('📤 Uploading content image ${i + 1}...');
          debugPrint('   File path: ${item.imageFile!.path}');
          debugPrint('   File exists: ${await item.imageFile!.exists()}');
          
          // Verify file exists
          if (!await item.imageFile!.exists()) {
            debugPrint('⚠️ Content image file not found, skipping: ${item.imageFile!.path}');
            // Skip this image or use placeholder
            continue;
          }
          
          final imageUrl = await _storageService.uploadNewsImage(item.imageFile!);
          
          // FIX: Check if upload was successful
          if (imageUrl == null || imageUrl.isEmpty) {
            debugPrint('⚠️ Failed to upload content image ${i + 1}, skipping');
            continue; // Skip this image instead of failing entire save
          }
          
          processedContent.add(ContentBlock(
            type: 'image',
            value: imageUrl,
            caption: item.caption,
          ));
          
          debugPrint('✅ Content image ${i + 1} uploaded: $imageUrl');
        } else if (item.type == 'image' && item.value.isNotEmpty) {
          // Keep existing image URL
          processedContent.add(item);
          debugPrint('✓ Keeping existing image URL: ${item.value}');
        } else if (item.type == 'text') {
          processedContent.add(item);
        }
      }

      // FIX: Final validation before saving
      if (mainImageUrl == null || mainImageUrl.isEmpty) {
        throw Exception('Main image URL is required but is null or empty');
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
        imageUrl1: mainImageUrl,
        content: processedContent,
        readBy: widget.news?.readBy ?? [],
        isNew: widget.news == null ? true : widget.news!.isNew,
      );

      if (widget.news == null) {
        await FirebaseFirestore.instance.collection('news').add(news.toMap());
        debugPrint('✅ New news created in Firestore');
      } else {
        await FirebaseFirestore.instance
            .collection('news')
            .doc(widget.news!.id)
            .update(news.toMap());
        debugPrint('✅ News updated in Firestore');
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
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving news: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
              'Gambar Utama *',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 12.h),
            if (_mainImageFile != null || _existingMainImageUrl != null)
                Stack(
                  children: [
                    InkWell(
                      onTap: () => _pickImage(isMainImage: true),    
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: _mainImageFile != null
                            ? Image.file(
                                _mainImageFile!, 
                                height: 200.h, 
                                width: double.infinity, 
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200.h,
                                    color: Colors.red[100],
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error, size: 50, color: Colors.red),
                                          SizedBox(height: 8.h),
                                          Text('Error loading image', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Image.network(
                                _existingMainImageUrl!, 
                                height: 200.h, 
                                width: double.infinity, 
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200.h,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200.h,
                                    color: Colors.red[100],
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, size: 50, color: Colors.red),
                                          SizedBox(height: 8.h),
                                          Text('Error loading image', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  Positioned(
                    bottom: 8.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: const Text(
                        'Tap untuk mengubah gambar',
                        style: TextStyle(color: Colors.white, fontSize: 12),
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
                    border: Border.all(color: Colors.red[300]!, width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 50.sp, color: Colors.red[300]),
                        SizedBox(height: 8.h),
                        Text(
                          'Pilih Gambar Utama (Wajib)', 
                          style: TextStyle(
                            fontSize: 14.sp, 
                            fontFamily: 'Poppins',
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
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
            Text(
              'Kategori *', 
              style: TextStyle(
                fontSize: 16.sp, 
                fontWeight: FontWeight.bold, 
                fontFamily: 'Poppins',
                color: _selectedCategories.isEmpty ? Colors.red[700] : Colors.black,
              ),
            ),
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
                     style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                IconButton(
                  onPressed: () => _removeContentItem(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (!isImageType)
              TextFormField(
                initialValue: item.value,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Teks', 
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                ),
                onChanged: (value) {
                  _contentItems[index] = ContentBlock(type: 'text', value: value);
                },
              )
            else ...[
              // Gambar konten yang sudah ada atau baru dipilih
              if (item.imageFile != null || (item.value.isNotEmpty && item.value.startsWith('http')))
                Stack(
                  children: [
                    InkWell(
                      onTap: () => _pickImage(contentIndex: index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: item.imageFile != null 
                            ? Image.file(
                                item.imageFile!, 
                                height: 200.h, 
                                width: double.infinity, 
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200.h,
                                    color: Colors.red[100],
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.error, size: 50, color: Colors.red),
                                          SizedBox(height: 8),
                                          Text('Error loading image', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Image.network(
                                item.value, 
                                height: 200.h, 
                                width: double.infinity, 
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200.h,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 50),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    // Overlay untuk menunjukkan gambar bisa diklik
                    Positioned(
                      bottom: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit, color: Colors.white, size: 16),
                            SizedBox(width: 4.w),
                            const Text(
                              'Tap untuk mengubah',
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              // Placeholder untuk memilih gambar pertama kali
              else
                InkWell(
                  onTap: () => _pickImage(contentIndex: index),
                  child: Container(
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 50.sp, color: Colors.grey[600]),
                          SizedBox(height: 8.h),
                          Text(
                            'Pilih Gambar',
                            style: TextStyle(
                              fontSize: 14.sp, 
                              fontFamily: 'Poppins',
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Caption field untuk gambar
              SizedBox(height: 12.h),
              TextFormField(
                initialValue: item.caption ?? '',
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Caption (opsional)',
                  hintText: 'Tambahkan keterangan gambar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  labelStyle: const TextStyle(fontFamily: 'Poppins'),
                  hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
                onChanged: (value) {
                  _contentItems[index] = ContentBlock(
                    type: 'image',
                    value: item.value,
                    caption: value,
                    imageFile: item.imageFile,
                  );
                },
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
            : const Text(
                'Simpan', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
      ),
    );
  }
}