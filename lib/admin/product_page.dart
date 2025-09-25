import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../data/dummy_products.dart';

class AdminProductPage extends StatefulWidget {
  final List<Product> initialProducts;

  const AdminProductPage({super.key, required this.initialProducts});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  late List<Product> products = List.from(dummyProducts);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _category = TextEditingController();

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
                  price: double.tryParse(_priceController.text) ??0,
                  imageUrl: _imageController.text,
                  description: _descController.text,
                  category: _category.text,
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
    _imageController.text = product.imageUrl;
    _descController.text = product.description;

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
                  price: double.tryParse(_priceController.text) ?? 0,
                  imageUrl: _imageController.text,
                  description: _descController.text,
                  category: _category.text,
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
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nama Produk")),
            TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Harga")),
            TextField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: "URL Gambar")),
            TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Deskripsi")),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(onPressed: onSave, child: const Text("Simpan")),
      ],
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _priceController.clear();
    _imageController.clear();
    _descController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Produk")),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
      body: products.isEmpty
          ? const Center(child: Text("Belum ada produk"))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return ListTile(
                  leading: p.imageUrl.isNotEmpty
                      ? Image.network(p.imageUrl, width: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image,
                          size: 50, color: Colors.grey),
                  title: Text(p.name),
                  subtitle: Text("Rp ${p.price.toStringAsFixed(0)}"),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailPage(product: p, isAdmin: true),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.red),
                    onPressed: () => _editProduct(index),
                  ),
                );
              },
            ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final bool isAdmin;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: isAdmin
            ? [
                IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                    }),
                IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                    }),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            product.imageUrl.isNotEmpty
                ? Image.network(product.imageUrl,
                    height: 200, fit: BoxFit.cover)
                : const Icon(Icons.image, size: 200, color: Colors.grey),
            const SizedBox(height: 16),
            Text(product.name,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Rp ${product.price.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 18, color: Colors.red)),
            const SizedBox(height: 12),
            Text(product.description,
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
