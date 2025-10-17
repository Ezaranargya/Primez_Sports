import 'package:flutter/material.dart';
import 'package:my_app/models/product_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditProductDialog extends StatefulWidget {
  final Product product;
  const EditProductDialog({super.key, required this.product});

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _brandController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _imageController = TextEditingController(text: widget.product.imagePath);
    _descController = TextEditingController(text: widget.product.description);
    _categoryController = TextEditingController(text: widget.product.categories.isNotEmpty ? widget.product.categories.first : "");
    _brandController = TextEditingController(text: widget.product.brand);
  }

  void _submit() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;

    final updatedProduct = widget.product.copyWith(
      name: _nameController.text,
      price: double.tryParse(_priceController.text) ?? widget.product.price,
      imagePath: _imageController.text,
      description: _descController.text,
      brand: _brandController.text,
      categories: [_categoryController.text],
    );

    Navigator.pop(context, updatedProduct);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Produk", style: TextStyle(fontWeight: FontWeight.bold)),
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
