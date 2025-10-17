import 'package:flutter/material.dart';
import 'package:my_app/models/product_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();

  void _submit() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;

    final product = Product(
      id: const Uuid().v4(),
      name: _nameController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      imagePath: _imageController.text,
      bannerImage: _imageController.text,
      description: _descController.text,
      brand: _brandController.text,
      categories: [_categoryController.text],
      purchaseOptions: [],
    );

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Tambah Produk", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nama Produk")),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: "Harga"), keyboardType: TextInputType.number),
            TextField(controller: _imageController, decoration: const InputDecoration(labelText: "URL Gambar")),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Deskripsi"), maxLines: 2),
            TextField(controller: _brandController, decoration: const InputDecoration(labelText: "Brand")),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: "Kategori")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text("Simpan")),
      ],
    );
  }
}
