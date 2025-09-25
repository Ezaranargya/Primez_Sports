import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/product_model.dart';
import '../../utils/formatter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final bool isAdmin;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.isAdmin = false,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool showOptions = false;
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFFE53E3E),
        actions: widget.isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: "Edit Produk",
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: "Hapus Produk",
                  onPressed: () {},
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      height: 250,
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.image, size: 200, color: Colors.grey),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  Formatter.currency(product.price),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      product.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showOptions = !showOptions;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53E3E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Opsi pembelian bisa lewat link di Sini",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Icon(
                                showOptions
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showOptions) ...[
                        Column(
                          children: product.purchaseOptions.map((option) {
                            return GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(option.link);
                                final messenger = ScaffoldMessenger.of(context);

                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication
                                      );
                                } else {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Tidak bisa membuka link")),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                child: Row(
                                  children: [
                                    Image.network(
                                      option.logoUrl,
                                      width: 30,
                                      height: 30,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "${option.storeName} - ${Formatter.currency(option.price)}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "*Harga dapat berubah sewaktu-waktu",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        iconSize: 28,
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              isFavorite ? Colors.red : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            isFavorite = !isFavorite;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFavorite
                                  ? "${product.name} ditambahkan ke favorite"
                                  : "${product.name} dihapus dari favorite"),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        iconSize: 28,
                        icon:
                            const Icon(Icons.share, color: Colors.black),
                        onPressed: () {
                          Share.share(
                            "Cek produk ini: ${product.name}\nHarga: ${Formatter.currency(product.price)}",
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
