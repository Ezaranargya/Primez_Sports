import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/services/product_service.dart';
import 'package:my_app/services/notification_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class EditProductScreen extends StatefulWidget {
  final String? productId;
  const EditProductScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  bool _isLoading = false;
  bool _dataReady = false;
  bool _imageChanged = false;
  bool _bannerChanged = false; 

  File? _imageFile;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  
  File? _bannerFile;
  Uint8List? _bannerBytes;
  String? _existingBannerUrl;
  
  String? _selectedKategori;
  String? _selectedSubKategori;

  final _namaController = TextEditingController();
  final _brandController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();

  List<Map<String, dynamic>> _opsiPembelian = [];

  static const _kategoriList = [
    'Soccer',
    'Basketball',
    'Running',
    'Tennis',
    'Other'
  ];

  static const _subKategoriList = [
    'Trending',
    'New Arrival',
    'Sale',
    'Featured'
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _brandController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (widget.productId != null) {
      await _loadProduct();
    } else {
      setState(() => _dataReady = true);
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (!doc.exists) throw Exception('Produk tidak ditemukan');
      final data = doc.data() as Map<String, dynamic>;

      final hargaValue = data['harga'] ?? data['price'] ?? 0;
      final hargaText = (hargaValue is num)
          ? hargaValue.toInt().toString()
          : hargaValue.toString();

      final kategori = data['kategori'] ??
          data['category'] ??
          (data['categories'] is List && data['categories'].isNotEmpty
              ? data['categories'][0]
              : null);

      final subKategori = data['subKategori'] ??
          data['subCategory'] ??
          (data['categories'] is List && data['categories'].length > 1
              ? data['categories'][1]
              : null);

      final opsi = (data['opsiPembelian'] ??
              data['purchaseOptions'] ??
              []) as List<dynamic>;

      if (!mounted) return;

      setState(() {
        _namaController.text =
            data['nama']?.toString() ?? data['name']?.toString() ?? '';
        _brandController.text = data['brand']?.toString() ?? '';
        _deskripsiController.text =
            data['deskripsi']?.toString() ?? data['description']?.toString() ?? '';
        _hargaController.text = hargaText;

        _selectedKategori = _kategoriList.firstWhere(
          (c) => c.toLowerCase() == (kategori ?? '').toLowerCase(),
          orElse: () => _kategoriList.first,
        );

        _selectedSubKategori = _subKategoriList.firstWhere(
          (c) => c.toLowerCase() == (subKategori ?? '').toLowerCase(),
          orElse: () => _subKategoriList.first,
        );

        _opsiPembelian = opsi.map((e) {
          if (e is Map<String, dynamic>) return e;
          return <String, dynamic>{};
        }).toList();

        _existingImageUrl = data['imageUrl']?.toString();
        _existingBannerUrl = data['bannerUrl']?.toString(); // ⭐ TAMBAHAN
        _isLoading = false;
        _dataReady = true;
      });
      
      debugPrint('✅ Product loaded - Banner URL: $_existingBannerUrl');
    } catch (e) {
      debugPrint('❌ Error loading product: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dataReady = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFile = null;
          _imageChanged = true;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageBytes = null;
          _imageChanged = true;
        });
      }
      
      debugPrint('✅ Main image selected');
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal pilih gambar: $e')),
      );
    }
  }

  // ⭐ TAMBAHAN: Function untuk pick banner
  Future<void> _pickBannerImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _bannerBytes = bytes;
          _bannerFile = null;
          _bannerChanged = true;
        });
      } else {
        setState(() {
          _bannerFile = File(pickedFile.path);
          _bannerBytes = null;
          _bannerChanged = true;
        });
      }
      
      debugPrint('✅ Banner image selected');
    } catch (e) {
      debugPrint('❌ Error picking banner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal pilih banner: $e')),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk wajib diisi!')),
      );
      return;
    }

    final harga = double.tryParse(_hargaController.text);
    if (harga == null || harga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga tidak valid!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final productName = _namaController.text.trim();
      final brandName = _brandController.text.trim();
      final isNewProduct = widget.productId == null;

      final success = await ProductService().saveOrUpdateProduct(
        productId: widget.productId,
        name: productName,
        brand: brandName,
        description: _deskripsiController.text.trim(),
        price: harga,
        categories: [
          _selectedKategori ?? _kategoriList.first,
          _selectedSubKategori ?? _subKategoriList.first
        ],
        purchaseOptions: _opsiPembelian,
        imageFile: _imageFile,
        imageBytes: _imageBytes,
        imageFileName: '$productName.jpg',
        existingImageUrl: _imageChanged ? null : _existingImageUrl,
        bannerFile: _bannerFile,
        bannerBytes: _bannerBytes,
        bannerFileName: '${productName}_banner.jpg',
        existingBannerUrl: _bannerChanged ? null : _existingBannerUrl,
      );

      if (!mounted) return;

      if (success) {
        try {
          final notificationService = NotificationService();
          
          if (isNewProduct) {
            await notificationService.sendNotificationToAllUsers(
              title: "🎉 Produk Baru!",
              message: "$productName dari $brandName baru saja hadir!",
              imageUrl: "",
              brand: brandName,
              type: "product",
              productId: widget.productId ?? "",
              categories: [
                _selectedKategori ?? "",
                _selectedSubKategori ?? ""
              ],
            );
            debugPrint('✅ Notifikasi produk baru berhasil dikirim');
          } else {
            await notificationService.sendGlobalNotification(
              title: "📢 Update Produk",
              message: "$productName telah diperbarui!",
              imageUrl: "",
              brand: brandName,
              type: "product",
              productId: widget.productId ?? "",
            );
            debugPrint('✅ Notifikasi update produk berhasil dibuat');
          }
        } catch (notifError) {
          debugPrint('⚠️ Produk berhasil disimpan, tapi notifikasi gagal: $notifError');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNewProduct
                  ? '✅ Produk berhasil ditambahkan & notifikasi terkirim!'
                  : '✅ Produk berhasil diperbarui!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal menyimpan produk'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saat menyimpan produk: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Tambah Produk' : 'Edit Produk'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProduct,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Image
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImagePreview(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(_imageFile != null || _imageBytes != null
                        ? 'Ganti Gambar Utama'
                        : 'Pilih Gambar Utama'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ⭐ TAMBAHAN: Banner Image Section
                  GestureDetector(
                    onTap: _pickBannerImage,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildBannerPreview(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickBannerImage,
                    icon: const Icon(Icons.panorama),
                    label: Text(_bannerFile != null || _bannerBytes != null
                        ? 'Ganti Banner'
                        : 'Pilih Banner Produk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  _buildTextField(
                      _namaController, 'Nama Produk *', Icons.shopping_bag),
                  const SizedBox(height: 16),
                  _buildTextField(
                      _brandController, 'Brand', Icons.branding_watermark),
                  const SizedBox(height: 16),
                  _buildTextField(_deskripsiController, 'Deskripsi Produk',
                      Icons.description, TextInputType.text, 3),
                  const SizedBox(height: 16),
                  _buildTextField(_hargaController, 'Harga *',
                      Icons.attach_money, TextInputType.number),
                  const SizedBox(height: 16),

                  _buildDropdownField(
                    label: 'Kategori',
                    selectedValue: _selectedKategori,
                    items: _kategoriList,
                    icon: Icons.category,
                    onChanged: (v) => setState(() => _selectedKategori = v),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Sub Kategori',
                    selectedValue: _selectedSubKategori,
                    items: _subKategoriList,
                    icon: Icons.layers,
                    onChanged: (v) => setState(() => _selectedSubKategori = v),
                  ),
                  const SizedBox(height: 16),

                  const Text('* Wajib diisi',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.all(16)),
                    child: const Text(
                      'SIMPAN PRODUK',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Image.network(
        _existingImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder('gambar'),
      );
    }

    return _buildPlaceholder('gambar');
  }

  // ⭐ TAMBAHAN: Banner preview widget
  Widget _buildBannerPreview() {
    if (_bannerBytes != null) {
      return Image.memory(
        _bannerBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    if (_bannerFile != null) {
      return Image.file(
        _bannerFile!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    if (_existingBannerUrl != null && _existingBannerUrl!.isNotEmpty) {
      return Image.network(
        _existingBannerUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder('banner'),
      );
    }

    return _buildPlaceholder('banner');
  }

  Widget _buildPlaceholder(String type) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          type == 'banner' ? Icons.panorama : Icons.add_photo_alternate,
          size: type == 'banner' ? 48 : 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap untuk pilih $type',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType? type,
    int maxLines = 1,
  ]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: type,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? selectedValue,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    final validValue = items.contains(selectedValue) ? selectedValue : null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          hint: Text('Pilih $label'),
          items: items
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item, maxLines: 2)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}