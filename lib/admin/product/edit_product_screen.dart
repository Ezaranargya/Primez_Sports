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
  
  bool _isLoading = false;
  bool _dataReady = false;
  bool _imageChanged = false;

  String? _imageBase64;
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
          SnackBar(content: Text('Gagal memuat produk: $e')),
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
          const SnackBar(content: Text('Gambar terlalu besar! Maksimal 900KB')),
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
      final success = await ProductService().saveOrUpdateProduct(
        productId: widget.productId,
        name: _namaController.text.trim(),
        brand: _brandController.text.trim(),
        description: _deskripsiController.text.trim(),
        price: harga,
        categories: [
          _selectedKategori ?? _kategoriList.first,
          _selectedSubKategori ?? _subKategoriList.first
        ],
        purchaseOptions: _opsiPembelian,
        imageBase64: _imageBase64 ?? '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Produk berhasil disimpan!'
              : '❌ Gagal menyimpan produk'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saat menyimpan: $e')),
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
                  
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ProductImage(
                          image: _imageBase64 ?? '', 
                          height: 200,
                          width: double.infinity,
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

                  
                  _buildTextField(
                      _namaController, 'Nama Produk *', Icons.shopping_bag),
                  const SizedBox(height: 16),
                  _buildTextField(
                      _brandController, 'Brand', Icons.branding_watermark),
                  const SizedBox(height: 16),
                  _buildTextField(_deskripsiController, 'Deskripsi Produk',
                      Icons.description,
                      ),
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
                        backgroundColor: Colors.blue, padding: const EdgeInsets.all(16)),
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

  
  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, [TextInputType? type, int maxLines = 1]) {
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
              .map((item) => DropdownMenuItem(value: item, child: Text(item, maxLines: 2)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
