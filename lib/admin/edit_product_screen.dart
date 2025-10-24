import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/utils/image_helper.dart';
import 'package:my_app/services/product_service.dart';
import 'package:my_app/pages/product/widgets/product_image.dart';

class EditProductScreen extends StatefulWidget {
  final String? productId;

  const EditProductScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  String? _imageBase64;
  bool _imageChanged = false;
  bool _isLoading = false;
  bool _dataReady = false;

  final _namaController = TextEditingController();
  final _brandController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();

  String? _selectedCategori;
  String? _selectedSubCategori;

  List<Map<String, dynamic>> _opsiPembelian = [];

  static const _kategoriList = ['Soccer', 'Basketball', 'Running', 'Tennis', 'Other'];
  static const _subKategoriList = ['Trending', 'New Arrival', 'Sale', 'Featured'];

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

      String? rawKategori = data['kategori']?.toString() ?? data['category']?.toString();
      String? rawSubKategori = data['subKategori']?.toString() ?? data['subCategory']?.toString();

      if (rawKategori == null && data['categories'] is List) {
        final categories = data['categories'] as List;
        if (categories.isNotEmpty) {
          rawKategori = categories[0]?.toString();
          if (categories.length > 1) rawSubKategori = categories[1]?.toString();
        }
      }

      print('rawKategori: $rawKategori');
      print('rawSubKategori: $rawSubKategori');
      print('kategoriList: $_kategoriList');
      print('subKategoriList: $_subKategoriList');

      final hargaValue = data['harga'] ?? data['price'] ?? 0;
      final hargaText = hargaValue is num ? hargaValue.toInt().toString() : hargaValue.toString();

      final opsiData = data['opsiPembelian'] ?? data['purchaseOptions'] ?? [];
      final opsi = opsiData is List ? List<Map<String, dynamic>>.from(opsiData) : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _namaController.text = data['nama']?.toString() ?? data['name']?.toString() ?? '';
        _brandController.text = data['brand']?.toString() ?? '';
        _deskripsiController.text = data['deskripsi']?.toString() ?? data['description']?.toString() ?? '';
        _hargaController.text = hargaText;

        // ✅ Cocokkan kategori/sub kategori dengan list (case insensitive)
        _selectedCategori = _kategoriList.firstWhere(
          (cat) => cat.toLowerCase() == (rawKategori ?? '').toLowerCase(),
          orElse: () => _kategoriList.first,
        );

        _selectedSubCategori = _subKategoriList.firstWhere(
          (sub) => sub.toLowerCase() == (rawSubKategori ?? '').toLowerCase(),
          orElse: () => _subKategoriList.first,
        );

        _opsiPembelian = opsi;
        _imageBase64 = data['imageBase64']?.toString();
        _isLoading = false;
        _dataReady = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dataReady = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final base64 = await ImageHelper.pickImageAsBase64();
      if (base64 == null) return;

      if (base64.length > 900000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gambar terlalu besar! Maksimal ~900KB')),
        );
        return;
      }

      setState(() {
        _imageBase64 = base64;
        _imageChanged = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal pilih gambar: $e')),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk harus diisi!')),
      );
      return;
    }

    if (_hargaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga produk harus diisi!')),
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
      final success = await ProductService().saveProduct(
        productId: widget.productId,
        nama: _namaController.text.trim(),
        brand: _brandController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        harga: harga,
        kategori: _selectedCategori ?? _kategoriList.first,
        subKategori: _selectedSubCategori ?? _subKategoriList.first,
        opsiPembelian: _opsiPembelian,
        imageBase64: _imageChanged ? (_imageBase64?? '') : '',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Produk berhasil disimpan!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Gagal menyimpan produk'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
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
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ProductImage(
                          imageBase64: _imageBase64,
                          width: double.infinity,
                          height: 200,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pilih Gambar'),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.branding_watermark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deskripsiController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Produk',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hargaController,
                    decoration: const InputDecoration(
                      labelText: 'Harga *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // ✅ Dropdown kategori
                  _buildDropdownField(
                    label: 'Kategori',
                    selectedValue: _selectedCategori,
                    items: _kategoriList,
                    icon: Icons.category,
                    onChanged: (value) => setState(() => _selectedCategori = value),
                  ),
                  const SizedBox(height: 16),

                  // ✅ Dropdown sub kategori
                  _buildDropdownField(
                    label: 'Sub Kategori',
                    selectedValue: _selectedSubCategori,
                    items: _subKategoriList,
                    icon: Icons.layers,
                    onChanged: (value) => setState(() => _selectedSubCategori = value),
                  ),

                  const SizedBox(height: 24),
                  const Text('* Wajib diisi', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'SIMPAN PRODUK',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ✅ versi aman dari DropdownButton
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isDense: true,
          isExpanded: true,
          hint: Text('Pilih $label'),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
