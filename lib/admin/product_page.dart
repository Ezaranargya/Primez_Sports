import 'package:flutter/material.dart';
import 'package:my_app/models/product_model.dart';
import 'package:my_app/admin/product_detail_page.dart';

class AdminProductPage extends StatefulWidget {
  final List<Product> initialProducts;

  const AdminProductPage({super.key, required this.initialProducts});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  late List<Product> products;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    products = List.from(widget.initialProducts);
  }

  void _addProduct() {
    _clearControllers();
    showDialog(
      context: context,
      builder: (_) => _productDialog(
        title: "Tambah Produk",
        onSave: () {
          if (_nameController.text.isNotEmpty &&
              _priceController.text.isNotEmpty) {
            setState(() {
              products.add(
                Product(
                  id: DateTime.now().toString(),
                  name: _nameController.text,
                  brand: "",
                  price: double.tryParse(_priceController.text) ?? 0,
                  imagePath: _imageController.text,
                  bannerImage: _imageController.text,
                  description: _descController.text,
                  categories: [_categoryController.text],
                ),
              );
            });
            _clearControllers();
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _editProduct(int index) {
    final product = products[index];
    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _imageController.text = product.imagePath;
    _descController.text = product.description;
    _categoryController.text =
        product.categories.isNotEmpty ? product.categories.first : "";

    showDialog(
      context: context,
      builder: (_) => _productDialog(
        title: "Edit Produk",
        onSave: () {
          if (_nameController.text.isNotEmpty) {
            setState(() {
              products[index] = Product(
                id: product.id,
                name: _nameController.text,
                brand: "",
                price: double.tryParse(_priceController.text) ?? 0,
                imagePath: _imageController.text,
                bannerImage: _imageController.text,
                description: _descController.text,
                categories: [_categoryController.text],
              );
            });
            _clearControllers();
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _productDialog({required String title, required VoidCallback onSave}) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nama Produk"),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Harga"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: "URL Gambar"),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Deskripsi"),
              maxLines: 2,
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: "Kategori"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text("Simpan"),
        ),
      ],
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _priceController.clear();
    _imageController.clear();
    _descController.clear();
    _categoryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kelola Produk",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: products.isEmpty
          ? const Center(
              child: Text(
                "Belum ada produk",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: p.imagePath.isNotEmpty
                          ? Image.asset(
                              p.imagePath,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      "Rp ${p.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        color: Colors.grey,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editProduct(index),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminProductDetailPage(product: p),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
